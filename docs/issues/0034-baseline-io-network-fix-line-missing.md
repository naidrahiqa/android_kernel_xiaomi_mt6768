---
id: 0034
title: EsTehAnget24.0 baseline tidak membawa garis fix I/O & network dari linimasa migrate-xxksu-driver (fq_codel default, swappiness cap 200, zram default disksize)
status: verified
severity: medium
area: config
opened: 2026-11-03
updated: 2026-11-03
fix_commit: "f743aede6c5d 7b8a5dff33d6 941dcbda7bca"
verified_on: "4.19.325-cip136-st20-EsTehAnget"
tags: [io, network, zram, qdisc, sysctl, restore, baseline-gap]
related: [0003, 0029, 0030]
---

## Issue

Baseline import `EsTehAnget24.0` (23 Okt 2026) chronically did not carry
several validated I/O & network fixes from the older development line
(`migrate-xxksu-driver`). The device therefore ran a different I/O & network
stack than the gotchas claim. Discovered 3 Nov 2026 during a deep I/O &
network code audit (macam subsytem: block, mm, net).

Three critical missing fixes:

1. **Default queuing discipline fq_codel** — devices fell back to
   `pfifo_fast`.
2. **`vm.swappiness` ceiling 200** — cap was back at the stock **100**.
3. **Kernel-side zram default disksize** — sizing relied fully on the vendor
   fstab `zramsize=55%` + the `/data/adb/modules/zram-fix` rescue module.

## Evidence

Proven by ancestry and source inspection on 3 Nov 2026 (post-rebase tip
`9f8cd36fc410`):

- `git merge-base --is-ancestor` → `709b52d0129e`, `826146b2e88e`,
  `adcd3ae96c0c` (also `e4de8ed591a0`, dyn_fsync import) — all NOT an
  ancestor of `EsTehAnget24.0`; `git branch -a --contains` places them on
  `migrate-xxksu-driver`.
- `kernel/sysctl.c:~1478`: swappiness entry had `extra2 = &one_hundred`
  (cap 100) in the shipped baseline.
- `grep late_initcall drivers/block/zram/` → nothing: no kernel-side
  default disksize; `zram_drv.c:1711` has plain `disksize_store` only.
- `out/.config` (pre-restore): `# CONFIG_NET_SCH_FQ_CODEL is not set`,
  `# CONFIG_NET_SCH_DEFAULT is not set` while `CONFIG_NET_SCHED=y`;
  fq_codel sources present in `net/sched/` (sch_fq_codel.c) but unused.
- `block/elevator.c:986` shows devices with blk-mq auto default to
  mq-deadline if no explicit default is configured.
- The same gap also explains two past gotchas reading stale:
  fq_codel "restore" row + zram default row referenced fix commits that
  were not on this branch.
- Related but NOT part of this fix (left queued): ADIOS scheduler series
  (`94218840ef17` + 5 fixes), dyn_fsync (`fs/dynamic_fsync.c` import +
  `3427409b60b8` READ/WRITE_ONCE), FUSE refrigerate `e4de8ed591a0`,
  defconfig-only ESP-offload tokens from `3937e69ad8a0` — see
  the analysis summary in the 2026-11-03 changelog entry.

## Root cause

Baseline import flow picked its own curated commit set (24 Okt 2026 audit
lineage) by hand and did not splice the fix commits living on
`migrate-xxksu-driver` (tip `4a50eef39cf4`, branch dormant since 10 Okt
2026). The 2026-11-03 rebase onto `mt6768-S/lineage-24.0` `ac0b904fc30d`
replayed the 21 local commits faithfully (`range-diff` all `=`) so it does
NOT worsen this gap — the gap predates the rebase and survived it.

## Fix

Restored per-concept, from the original commits (kept original authorship,
provenance noted in the message bodies):

- R1 — `defconfig: restore fq_codel as the default queuing discipline`
  (`7b8a5dff33d6`): `NET_SCH_FQ_CODEL=y` + `NET_SCH_DEFAULT=y` +
  `DEFAULT_FQ_CODEL=y` in `selene_defconfig` (restore `709b52d0129e`).
- R2 — `mm: sysctl: allow swappiness up to 200` (`f743aede6c5d`): new
  `two_hundred` constant, swappiness `extra2` → `&two_hundred`; runtime
  default stays 100 (restore `826146b2e88e`).
- R3 — `block: default zram disksize to 50% of RAM capped at 4GB`
  (`941dcbda7bca`): late_initcall apply of `disksize = 50% RAM cap 4GB`
  before userspace; fstab zramsize write hits EBUSY and mkswap/swapon
  continue with kernel value (restore `adcd3ae96c0c` + policy update
  `fe325d369c3e` = AOSP/CAF 50% default, not the original 75%).

## Verification

- Build gate: passed — Greenforce Cirrus clang 24.0.0, `MAKE_EXIT=0`;
  post-regen `.config` shows `CONFIG_NET_SCH_FQ_CODEL=y`,
  `CONFIG_NET_SCH_DEFAULT=y`, `CONFIG_DEFAULT_FQ_CODEL=y` and
  `CONFIG_CLANG_VERSION=240000` (toolchain fingerprint healthy, issue 0033).
- Hardware flash-test 3 Nov 2026 (selene `65cb03c00702`, 21061119AG):
  - `uname -r` = `4.19.325-cip136-st20-EsTehAnget`, build `#3 Tue Nov 3
    21:07:42 WIB 2026`, `/proc/version` = Cirrus clang 24.0.0.
  - R1 — `tc qdisc show` (via root): default `fq_codel` on `wlan0`
    (4 queues), `ccmni0` and `ap0` (limit 10240p, ecn, flows 1024).
  - R2 — swappiness runtime default **100**; write **200 accepted**
    (read back 200), write **250 rejected** (value stays 100) →
    ceiling 200 active; value restored to 100 after the test.
  - R3 — `/sys/block/zram0/disksize` = `2996133888` B = **2857 MB**,
    exactly 50% of totalram (~5.58 GB) — not the fstab 55% value → the
    size comes from the kernel-side late_initcall. `/proc/swaps` shows
    `/dev/block/zram0` active (2925908 kB, SwapTotal 2925908 kB).
    Causality clincher: the rescue module is not installed on this
    device at all (`/data/adb/modules/` holds only
    hma_oss_zygisk/nomount/rezygisk/xiaomicamera/zygisk_lsposed), so no
    userspace path could have written the size.
  - The `dmesg` `default disksize` line was not captured via
    `su -c dmesg` (log buffer restricted/rotated after boot) — the
    causality above rests on the value + absent-module evidence.
  - Root sanity in the same session: `su -c id` = `uid=0 …
    context=u:r:ksu:s0`; manager `com.resukisu.resukisu` versionCode
    35257 ≥ driver `KSU_VERSION` 35257 (issue 0008 addendum).
- Issue upgraded to `verified` with the on-device evidence above.

## Regression test

- Whenever this baseline is re-imported or another branch is recreated,
  run the ancestry probe first:
  `git merge-base --is-ancestor 709b52d0129e HEAD && git merge-base --is-ancestor 826146b2e88e HEAD && git merge-base --is-ancestor fe325d369c3e HEAD`
  — all three must be ancestors before one claims these features work.
- After any defconfig regen: `grep -E 'NET_SCH_DEFAULT|DEFAULT_FQ_CODEL' out/.config`
  (checks symptoms from the gotcha-config table).
- Boot: `dmesg | grep 'default disksize'` must show the late_initcall line.
