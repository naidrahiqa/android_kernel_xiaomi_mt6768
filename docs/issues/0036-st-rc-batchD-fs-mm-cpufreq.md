---
id: 0036
title: Sync Batch D dari linux-4.19.y-st-rc (fs/mm/cpufreq + bpf rtt_min, manual port untuk conflict)
status: fixed-build-only
severity: medium
area: fs
opened: 2026-11-07
updated: 2026-11-07
fix_commit: "55c79e12760f f40208bb30cf 7283f24c0df2 017ab1cb9cd4 58ac4f9f98db af9825ad1aac 3be33827d44e a7700397c7c2 99180c24a62d 1a20d44beee1 6f9e9d6b216b cf7c4ea7b756 b967b9317b37"
tags: [st-rc, sync, fs, mm, cpufreq, batch-d]
related: [0035]
---

## Issue

Lanjutan Batch C (issue 0035). Batch D mengambil sisa `fs/mm/cpufreq` yang
relevan untuk Selene dari `linux-4.19.y-st-rc`. Total 13 commit
topo-order, 7 apply bersih + 6 conflict butuh port manual per-hunk
(`-X theirs` dilarang).

## Batch D (13, oldest-first)

```text
d796111376bb ext4: stop retrying saturated xattr cache entries [CLEAN]
aafb18ea7844 ext4: clear error before retrying inode xattr space fallback [CLEAN]
fe900bc71d56 mm/huge_memory: fix huge_zero_pfn race [CLEAN]
627dbd913d82 mm/vmscan: report RCU-tasks quiescent states in shrink_lruvec() [CLEAN]
7983340f5727 cpufreq: schedutil: Fix rate limit overflow [CONFLICT - port manual]
8d734db97256 f2fs: reject overlapping move range after len expansion [CLEAN]
d29436aa586a cpufreq: schedutil: Fix self-contradictory comment in sugov_iowait_apply() [CLEAN]
49c52f443a2e ext4: skip extra isize expansion during mount to prevent deadlock [CLEAN]
92417a748a8d fuse: set ff->flock only on success [CONFLICT - port manual]
f9f6e27e2d07 f2fs: validate inline dentry name lengths before conversion [CONFLICT - port manual]
3a1fe75c4db9 mm/swap: reject swapon() on filesystem-level encrypted files [CONFLICT - port manual]
0eceef464ddb cpufreq: initialize policy rwsem before sysfs publication [CONFLICT - port manual]
88588102ee3a bpf: Fix out-of-bounds read of rtt_min in sock_ops [CONFLICT - port manual]
```

Dikecualikan (platform lain): `imx6q`, `spear` cpufreq.

## Fix

Backup: `backup/pre-batchD-20261107`. Clean via
`git show --binary <sha> | git apply --index`, conflict via edit manual
per-hunk + commit body asli + `(cherry picked from commit ...)` footer.
1 konsep = 1 commit.

Metode manual terverifikasi:
- `7983340f5727 schedutil`: upstream single `rate_limit_us` → lokal split
  `up/down_rate_limit_us`; dibuat 2 helper `(s64) * NSEC_PER_USEC`
  untuk store + start (commit `58ac4f9f98db`).
- `92417a748a8d fuse`: pindah `ff->flock = true` setelah `fuse_setlk` sukses.
- `f9f6e27e2d07 f2fs`: tambah validasi `name_len` vs `F2FS_NAME_LEN` dan `d.max`.
- `3a1fe75c4db9 mm/swap`: cek `IS_ENCRYPTED` setelah `inode_lock`, error via
  `bad_swap_unlock_inode` (label tersedia di 4.19).
- `0eceef464ddb cpufreq`: pindah `init_rwsem` sebelum `kobject_init_and_add`.
- `88588102ee3a bpf`: ganti open-coded `rtt_min` dengan
  `SOCK_OPS_GET_FIELD(rtt_min, rtt_min.s[0].v, struct tcp_sock)` (guard `is_fullsock`).

Hasil: 13 commit di atas `bdde2a01028b`, 12 file (+95/-42).

## Verification

- [x] Status clean, 13 commit di atas `bdde2a01028b` (VERIFIED)
- [x] `scripts/check-toolchain.sh` OK — Greenforce Cirrus 24.0.0 (VERIFIED)
- [x] Build lokal `MAKE_EXIT=0` (`/tmp/opencode/build-batchD.log`), `error: 0`,
  `Image.gz-dtb` 12M, `CLANG_VERSION=240000`, `KSU`+`NOMOUNT` ada (VERIFIED)
- [ ] Flash & boot-test selene — NOT CHECKED

## Regression test

- Jangan `-X theirs` wholesale untuk file yang diverge (cpufreq.c, swapfile.c,
  filter.c) — resolve per-hunk.
- Build gagal → revert commit itu, catat di sini.
