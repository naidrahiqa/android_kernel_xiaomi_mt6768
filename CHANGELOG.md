# CHANGELOG — EsTehAnget Edition (Xiaomi Selene / MT6768)

Kernel by [@naidrahiqa](https://github.com/naidrahiqa)

---

## 2026-11-03 — BakaSU rev 4557 sync + Restorasi Fix I/O & Network (upstream sync & config restore batch)

+ **bakasu:** sync driver ke upstream `Baka-SU/BakaSU@main` rev **4557** (`516d3e87`, +21 commit) — module preinit (`preinit/` + runner nolibc), feature `shell_su_adb_only`, standarisasi `module_blacklist` param (menggantikan `module_load_filter` custom), BTF parser untuk probing ABI kernel baru, migrasi `ksys_unshare`→`ksyscall`, bersih-bersih guard yang inert di 4.19; `KSU_VERSION` **35229 → 35257** + `BAKASU_REV_COUNT` 4557 (`9f8cd36fc410`). `include/uapi` symlink di-repacking `../uapi` (artifact flatten — build preinit runner butuh `headers_install` dulu pada fresh out/). Cherry-pick masuk `EsTehAnget-HyperOS` (`80c3e9ac5c8f`) + force-push `--force-with-lease` berhasil. **Manager APK versionCode ≥ 35257 WAJIB terinstall sebelum flash kernel ini** (`docs/issues/0008`); rollback versi = 2 baris Kbuild.
+ **restore (issue `0034`):** analisa mendalam I/O & network menemukan garis fix dari linimasa dev lama `migrate-xxksu-driver` tidak pernah di-bawa ke baseline import `EsTehAnget24.0` — rebase Skyron tidak menyebabkan hilang, gap-nya lebih tua. Tiga restore:
  + **fq_codel default qdisc** (`7b8a5dff33d6` — restore `709b52d0129e`): tanpa `NET_SCH_DEFAULT`, pilihan default `pfifo_fast` → tanpa flow-separation untuk hotspot/tethering.
  + **sysctl swappiness cap 200** (`f743aede6c5d` — restore `826146b2e88e`): apapun di atas `100` ditolak di baseline; runtime default tetap 100, cap untuk userspace diperlakukan 200 untuk unit RAM 6GB dengan zram sebagai swap utama.
  + **zram default disksize 50% RAM cap 4GB kernel-side** (`941dcbda7bca` — restore `adcd3ae96c0c` + final policy `fe325d369c3e`): di-set di `late_initcall` sebelum userspace; fstab `zramsize=55%` write kena EBUSY dan mkswap/swapon jalan pakai nilai kernel — baseline dulu jalan tanpa ini (rescue module `zram-fix` menambal boot race).
+ **kandidat antrean (tier-2, benchmark A/B dulu):** TCP CC BBR vs westwood vs cubic, page-cluster 0, XANMOD mq-deadline (sequential + front_merges off), rq_affinity=2, NAPI poll weight wlan/P2P (butuh driver `6b6efdb0bc43`), zram CMA alloc (`82298e5dc429`) — juga kandidat restore opsional: ADIOS series (6 komit), dyn_fsync, FUSE refrigerate, ESP-offload defconfig.
+ **validasi:** build lokal Greenforce Cirrus 24.0.0 `MAKE_EXIT=0` (`NET_SCH_FQ_CODEL`/`NET_SCH_DEFAULT`/`DEFAULT_FQ_CODEL` on di `.config`) → **flash-test hardware 3 Nov 2026 lulus** (zip `EsTehAnget-Greenforce-Clang-745a603-03112026-r1.zip`, device `65cb03c00702`): uname `4.19.325-cip136-st20-EsTehAnget` #3, fq_codel jadi default di `wlan0` (4 queue)/`ccmni0`/`ap0`; swappiness write 200 **diterima** & write 250 ditolak (cap 200 aktif, default runtime tetap 100); zram0 disksize **2857 MB = tepat 50% totalram** — sumber kernel-side (`late_initcall`), modul rescue `zram-fix` bahkan tidak terpasang di device; root `u:r:ksu:s0` + manager `com.resukisu.resukisu` versionCode **35257** (≥ driver). Issue `0034` + `0008` naik ke **verified**.

## 2026-11-03 — Rebase ke upstream `mt6768-S/lineage-24.0` (rebase Skyron) + Mali r56p0

+ **trees:** rebase penuh `EsTehAnget24.0` **dan** `EsTehAnget-HyperOS` ke tip baru `mt6768-S/lineage-24.0` (`ac0b904fc30d` — upstream menulis-ulang branch-nya: import Xiaomi di-reimport, history diluruskan jadi linear). 21 commit lokal ter-replay tanpa kehilangan patch (`git range-diff` semua `=`); satu-satunya delta patch logspam = resolve konflik `mtk_ts_blk_ntc.c` (hunk kita vs upstream `mtkts_blkntc_dprintk()` yang setara — punya upstream yang dipertahankan).
+ **gpu:** upstream mengganti seluruh Mali DDK **r32p1 → r56p0** (`9ee8a846c41b`, ±514 file, `drivers/gpu/mediatek/gpu_mali/mali_valhall/mali-r56p0/`). Ikut konsisten: `selene_defconfig` di kedua branches dibump `CONFIG_MTK_GPU_VERSION="mali valhall r56p0"` (`6fa7e3cd67f2`, `d495d7b679d5`) — string ini pilihan yang mengarahkan Makefile MTK GPU ke dir `mali-rNNNNpN`, jadi bump = wajib, bukan kosmetik. Defconfig vendor k6xxx (chip lain) sengaja tetap r32p1 mengikuti upstream.
+ **upstream fix yang ikut tertarik ke base baru:** fix CFI failure di connectivity (`gen4m` MD RF notify + OID_PNP_SET_POWER, wmt/bt/fmradio callback), `chg_type_det` TCPC missing handling, batalkan WARN `force_get_tbat_internal`, `page_alloc` highatomic reserve di watermark fastpath, zram boleh alloc CMA, `setlocalversion` tidak lagi menambah `+`, vendor `mt6768_defconfig` di-regen (`-Skyron` + LTO/CFI/SHADOW_CALL_STACK — **bukan** target build kita; `selene_defconfig` tetap ringkas di-set sendiri).
+ **defconfig branding:** commit `dieD karnul` (`LOCALVERSION="-dieD"` di vendor `mt6768_defconfig`) gugur by choice — file vendor defconfig kini up-to-upstream penuh; identitas build kita tetap dari `selene_defconfig` (`-EsTehAnget` / `-EsTehAnget-HyperOS`).
+ **docs:** SHA commit lokal di issue 0029/0031/0033 + `docs/skill-system-audit.md` di-refresh ke SHA pasca-rebase (`fbd5f8b0210a`); SHA di entri changelog yang lebih lama sengaja dibiarkan (rekam jejak sebelum rewrite).
+ **validasi:** build lokal Greenforce Cirrus 24.0.0 `MAKE_EXIT=0`, `Image.gz-dtb` 12.4 MB keluar, `strings out/vmlinux` = `r56p0-19eac0 (UK version 11.46)`, config kunci `KSU`/`KSU_MANUAL_HOOK`/`KSU_HOSTSREDIRECT`/`NOMOUNT` semua on. **GPU DDK r56p0 belum dites di hardware** — userspace GPU ROM wajib dianggap kompatibel dulu saat flash-test berikutnya; warning bisu di defconfig vendor upstream (LTO/CFI/SCS) tidak ikut karena bukan config kita.

## 2026-10-23 — EsTehAnget24.0 Baseline: Rebrand + Integrasi Inti + Pipa Rilis

+ **trees:** baseline fresh dari `creativchic/lineage-24.0` (`fa7077ae`) + `mt6768-S` (`6d3888fc`) + local commits; branch utama **`EsTehAnget24.0`**; branding uname pindah ke belakang — `4.19.325-cip136-st20-EsTehAnget+` via `CONFIG_LOCALVERSION="-EsTehAnget"` + `localversion-cip`/`localversion-st` (file `localversion` & `VERSION` tidak dipakai). Komit penataan awal: `978ac210` (drop CI in-tree), `1b97d049` (carry README/CHANGELOG/docs), `ce36fcc7` + `26a811ce` (gitignore local-only), `b183043` (selene_defconfig).
+ **bakasu:** import upstream `Baka-SU/BakaSU` rev `4536` (`dac2d186`) sebagai in-tree copy `drivers/bakasu/` (`23fdab39858c`), anchor manual hook ke syscalls inti (`fs/open.c`, `fs/stat.c`, `fs/exec.c`, `kernel/reboot.c` — `fba3aea6e28e`); `KSU_VERSION=35229` **ditahan** (formula 35236 di rev 4536) biar pasangan manager APK tersedia; `CONFIG_KSU_HOSTSREDIRECT=y` + file hostsredirect local-only di-restore.
+ **fs:** import NoMount **v2.2.0** (`NOMOUNT_BASE_VERSION "22"`) dengan 5 guard 4.19 di-reapply manual (`a45fb26239e3`; guard rule-init di-reapply tangan setelah blok upstream pindah ke `nm_resolve_anchor_locked()`), `CFLAGS_nomount.o += -std=gnu11 -Wno-declaration-after-statement`.
+ **defconfig:** enable BakaSU + NoMount + blok DroidSpaces v6.6.0 (`8c3cd3a558d3`) — SYSVIPC, POSIX_MQUEUE, USER_NS, CGROUP_DEVICE/PIDS/NET_PRIO/NET_CLASSID/CFS_BANDWIDTH, TMPFS_POSIX_ACL/XATTR, NF_TABLES, IP6_NF_NAT + MASQUERADE, MACVLAN, XT_MATCH_ADDRTYPE, NF_CT_NETLINK; simbol yang tidak ada di 4.19 di-skip dengan catatan (FW_LOADER_COMPRESS, NF_CONNTRACK_NETLINK→NF_CT_NETLINK, dst.).
+ **docs:** seluruh import + perencanaan config direkam di `docs/issues/0030-fresh-import-bakasu-nomount-droidspaces.md`.
+ **ci/release (kit):** build hijau ×3 (`39899882633`, `39908169846`, `39920527490`) + lint hijau; zip naming kini memuat **sha kernel** (bukan sha kit); tiap `example-build` sukses terbit sebagai release `r<N>` di [`naidrahiqa/selene-releases`](https://github.com/naidrahiqa/selene-releases) — rilis verifikasi pertama [`r15`](https://github.com/naidrahiqa/selene-releases/releases/tag/r15): zip 14.6 MB + `.sha256`, body berisi fingerprint build (uname, source commit, toolchain, defconfig). Repo kernel ini tetap nol CI.
+ **sisa:** flash-test hardware (BakaSU root, nomount, DroidSpaces *Check Requirements*) → issue `0030` naik ke *verified* setelah lolos di perangkat.

## 2026-10-23 — CI Dihapus dari Repo Kernel (Overhaul)

+ **ci:** remove all in-tree CI — `.github/workflows/build-all.yml`, `.github/legacy/*`, `.gitlab-ci.yml` (CIP GitLab pipeline), and `scripts/ci/{build-stats,release,notify-release,notify-failure}.sh` (`cc8199384347`):
  + build/release/notification now run **exclusively** from [`naidrahiqa/kernel-ci-kit`](https://github.com/naidrahiqa/kernel-ci-kit) via `workflow_dispatch` (`example-build.yml`) — run + artifact live in the kit repo
  + push to this repository no longer triggers anything; start builds manually with `gh workflow run example-build.yml -R naidrahiqa/kernel-ci-kit`
  + rationale: the `build-all` wrapper burned ~30 min of Actions time per push (even docs-only commits) while the kit can produce the same AnyKernel3 zip on demand
+ **docs:** README CI section, AGENTS.md (context, CI Toolkit, skill table, gotchas) rewritten for the kit-only workflow
+ **reference:** local reference remotes trimmed to `origin` + `upstream` (`mt6768-S/android_kernel_xiaomi_mt6768`) + `creativchic` (`lineage-24.0`) + `cip` — half-configured mirrors (bbr, gale, shockwave, selene-U, ViP3R, android.googlesource common) and the local `fire` remote removed

## 2026-10-18 — FUSE Scoped Storage Fix, Vendor Bugfix & Upstream CIP Sync

+ **drivers/mmc/host/mtk-sd-dbg:** fix race condition and silent out-of-bounds memory corruption in MMC host debug log ring buffer (`__dbg_add_host_log`):
  + unconditional dedicated `msdc_dbg_lock` spinlock protecting ring buffer writes
  + strictly clamp `dbg_host_cnt` against underflow (`< 0`) and overflow (`>= 40000`)
  + sanitize reading bounds with `READ_ONCE()` in `mmc_cmd_dump` and fix `copy_from_user` in `msdc_debug_proc_write`
  + closes Issue `#0025` (root cause of silent panic / unexpected shutdown clusters)
+ **fs/pstore/pmsg:** switch `pmsg_lock` to `rt_mutex` to avoid priority inversion (upstream backport `f9e761541e87` by Google kernel-team) — eliminates UI frame drops/jank when logd and background tasks contend on `/dev/pmsg0`
+ **mm/shmem:** fix data race in `shmem_getattr()` by wrapping `generic_fillattr()` with `inode_lock_shared()` / `inode_unlock_shared()` (backport `9fb9703cd43e`)
+ **drivers/misc/mediatek/spi_slave:** fix invalid `kfree` on static `spislv_chip_info` struct in `spi_slave_remove` — prevents Bad SLAB free / Kernel Panic during device unbind/teardown
+ **net/wireless:** stop NAN and P2P in `__cfg80211_leave` (upstream backport `e1696c8bd005`) — prevents race / `__cfg80211_disconnected` WARN_ON when hotspot/Wi-Fi is toggled off
+ **net/bluetooth:** backport L2CAP concurrency and lifecycle fixes from CIP:
  + `e2b0b3461e9d`: hold connection reference to fix UAF in channel timeout (`l2cap_chan_timeout`)
  + `35e95dbb72e5`: serialize accept queue access and pin channel to eliminate UAF in `l2cap_sock_cleanup_listen` vs `l2cap_conn_del`
+ **net/ipv6:** use RCU-safe `ipv6_get_lladdr()` in `mcast` (fix `26394fc118d6`) — prevents General Protection Fault in `mld_ifc_work`
+ **net/netfilter:** CIP backport security and boundary hardening:
  + `d182744a2e54`: widen NAT rewrite delta to s32 in `sip_help_tcp()` to prevent buffer wrap and UAF in SIP header parser
  + `b652ba518f2f`: mark malformed IPv6 extension headers for hotdrop in ip6tables
  + `5ad5de1a1c59`: replace unsafe `sprintf` with `scnprintf` in conntrack SIP NAT helper to prevent stack OOB
  + `2ba8bebf745b`: restrict `xt_mac`, `xt_owner`, `xt_physdev`, `xt_realm` to inet family
+ **net/ipv4 & core:** bound `tcp_reordering` sysctl writes and compute `size_needed` as u64 in `tcp_mtu_probe()`; prevent refcount warning on dying rule in `fib_rules_dump()`; introduce `skb_pull_data` helper
+ **scripts/fix-fuse-storage.sh:** standalone & daemon script for Android 15/16 Scoped Storage bypass:
  + dynamic multi-user bind-mount `/data/media/<uid>/Android/{data,media,obb}` -> `/storage/emulated/<uid>/Android/{data,media,obb}` with `--make-shared`
  + eliminates `Rejected access to app-private dir on FUSE` (TikTok 0% download & photo save bug) caused by lack of `fuse_bpf.o` in custom ROM APEX
  + auto-heals media DAC permissions (775/664 `media_rw:media_rw` for DCIM, Pictures, Download, etc.) and app cache staging dirs
  + watchdog daemon recovers mounts automatically if MediaProvider or vold remounts storage
  + self-install option (`--install`) via root or ADB host push
+ **scripts/anykernel.sh & ak3:** auto-deploy storage-fix to `/data/adb/boot-completed.d/` and register `/data/adb/modules/storage-fix/` (v1.3) during kernel flash — eliminates need to manually download or flash a separate module zip
+ **defconfig:** remove duplicate `CONFIG_FW_LOADER_USER_HELPER=y` and `CONFIG_IP6_NF_MANGLE=y` overrides in `selene_defconfig` (100% warning-free build configuration)
+ **docs:** update issue `#0003` and skill `storage-scoped` with repository script and automated AnyKernel3 deployment details

## 2026-10-17 — Anti-Root Detection Hardening (Cmdline Spoofing, SELinux-Hide & /proc Hardening)

+ **fs/proc/task_mmu:** anti memory-inspection — filter sensitive VMAs from `/proc/<pid>/maps` and `/proc/<pid>/smaps` for untrusted UIDs (`uid >= 10000`):
  + hides injected libraries and binaries matching `zygisk`, `lsposed`, `shamiko`, `magisk`, `kernelsu`, `bakasu`, `frida`, `xposed`, `libriru`
  + hides mappings originating from `/data/adb/` and `/data/local/tmp/`
  + leaves system services (`uid < 10000`), root (`uid 0`), and ptrace/admin debuggers with full visibility
+ **kernel/module:** sanitize `/proc/modules` for untrusted apps (`uid >= 10000`) — returns empty list so the kernel appears monolithic without LKMs
+ **fs/proc/version:** sanitize `/proc/version` for untrusted apps — strips non-ASCII bytes (e.g. emoji) and replaces custom branding (`PawwwNunungggg`) with clean standard version string
+ **net/unix:** sanitize `/proc/net/unix` for untrusted apps — hides abstract and pathname sockets containing `zygisk`, `magisk`, `frida`, or `lsposed`
+ **fs/proc/cmdline:** sanitize security parameters in `/proc/cmdline` — stream-based zero-allocation filtering for userspace reads:
  + `androidboot.selinux=permissive` → `androidboot.selinux=enforcing` (aligns cmdline string with real Enforcing state)
  + `androidboot.veritymode=disabled` → `androidboot.veritymode=enforcing`
  + `androidboot.verifiedbootstate=orange` → `androidboot.verifiedbootstate=green`
  + `androidboot.vbmeta.device_state=unlocked` → `androidboot.vbmeta.device_state=locked`
+ **bakasu:** default `ksu_selinux_hide_enabled = true` and provide `ksu_selinux_hide_auto_enable()`:
  + auto-engage `selinux_hide` immediately after `apply_kernelsu_rules()` creates `backup_policydb` and during `on_post_fs_data()`
  + prevents `ksu_selinux_hide_drop_backup_if_unused()` from dropping the clean backup policydb at boot completion
  + app UIDs (`uid >= 10000`) evaluating SELinux types (e.g. `u:object_r:ksu_file:s0` probe by Wondr by BNI, issue #0019) get clean `-EINVAL` matching a stock untampered kernel
+ docs: issue `0019` created with evidence from device capture (`logcat.txt` bounded transition rejection & cmdline flags); issue `0018` fix_commit updated to `61e5b261667c`

## 2026-10-16 — Issue #0017 Verified on R04 + Local-Build Toolchain Guard

+ docs: issue `0017` (perf batch — gate `dprec_logger`, drop `cmdq_test.o`, enable ThinLTO) moved `fixed` → **`verified`** — all 6 checklist items passed on hardware, verified against the **CI R04** artifact (commit `b83b9b0b8d8a`, Greenforce Clang 24.0.0), not a local build
+ verify: `cmdq_test_init` **0 hits** in `System.map`, no real undefined symbols; `DISPMSG`/`DISPCHECK`/`dprec_logger` **0 hits** in dmesg (the `g_mobilelog` gate works); camera 0.6X/1.0X/2.0X + display scroll clean, no freeze/force-close
+ **find:** the local build had silently used **system clang 22.1.8** instead of Greenforce 24.0.0 — the `greenforce-clang/` checkout **is** on disk, but its `bin/` was not in `PATH`, so `make` picked up `CC=clang` from `/usr/bin`. No error, build was valid, but **PGO/Polly were silently lost**; the artifact ended up on the device while `uname` still printed the "Greenforce" name
+ scripts: **`check-toolchain.sh`** (new) — local-build guard: checks the `Cirrus` vendor marker in the clang banner, exits 1 when it is not Greenforce (and prints the `PATH` line to fix it). Wired into skill `build-local-test` step 1 & step 2
+ docs: new gotcha in AGENTS.md — "local build looks successful but uses the wrong toolchain"
+ **fix (issue `0018`):** camera/ISP no longer floods dmesg at **±12,000 lines/min** while the camera is in use — four changes, all keyed to the same `ISP_DBG_INT` mask:
  + `camera_isp.h`: drop `#define KERNEL_LOG` — the vendor's "enforce kernel log enable" left `IspInfo.DebugMask = ISP_DBG_INT` as the boot default (same ENG-code-in-user-build class as `cmdq_test.o` in #0017)
  + `camera_isp.c`: one guard at the top of `IRQ_LOG_KEEPER()` — `_LOG_INF`/`_LOG_DBG` entries are no longer buffered (hence never flushed by `ISP_BH_Workqueue`) unless `DebugMask & ISP_DBG_INT`; closes **all 56 ungated call sites** (`P1_SOF`, `CAMA/CAMB PHY cqcnt`, …) in one place. `_LOG_ERR` stays buffered for `ISP_DUMP_ISR_LOG`
  + `camera_isp.c` `ISP_SET_VIR_CQCNT`: success-path `LOG_NOTICE` → `LOG_DBG` — that ioctl alone produced **9,896 lines / 113 s** (48% of the flood); the `copy_from_user failed` error path stays `LOG_NOTICE`
  + `fdvt/4.0/camera_fdvt.c`: per-IRQ `[FDVT] Receive IRQ` `LOG_INF` → `LOG_DBG` (908 lines)
  + runtime behavior is preserved: `ISP_DEBUG_FLAG` ioctl still turns every layer back on for debugging, no rebuild needed
+ docs: issue `0018` created with the exact per-message breakdown from the R04 capture (20,700 lines / 113 s)

> ⚠️ **Local builds:** run `scripts/check-toolchain.sh` **before** `make`.
> An exit 1 means the build will silently fall back to system clang and the
> result is technically valid but without Greenforce optimizations — exactly
> what happened on Oct 15.

## 2026-10-15 — xxKSU Removed, BakaSU Becomes the Single Root Driver

+ drivers: drop `drivers/kernelsu/` (93 files, 17,986 lines) + `scripts/check-xxksu.sh` — xxKSU `backslashxx/KernelSU` v3.3.1 retired permanently, one root driver only
+ drivers: remove the Kconfig choice `ROOT_SOLUTION` (KSU_XXKSU / KSU_BAKASU); keep only `source drivers/bakasu/Kconfig`
+ drivers: `drivers/Makefile` two obj-conditional lines collapse to one — `obj-$(CONFIG_KSU) += bakasu/`
+ defconfig: `CONFIG_KSU_XXKSU=y` → `CONFIG_KSU=y` + `CONFIG_KSU_MANUAL_HOOK=y`; drop `KSU_LSM_SECURITY_HOOKS` & `KSU_HEURISTIC_IN_TREE_BUILD` (xxKSU-only symbols, silently discarded by `olddefconfig`)
+ ci: multibuild 4 variants → **2 variants** (`bakasu` NoMount off, `bakasu-nomount-droidspaces` NoMount on); DroidSpaces is the default defconfig, so it rides along in both variants
+ ci: `release.sh` zip guard `4` → `2` (**blocker bug** — with 2 variants the old guard would have made every release fail to publish), Root Driver note becomes BakaSU `KSU_VERSION=35229`
+ ci: Telegram notifications (`notify-release.sh` / `notify-failure.sh`) → "2 variants", variant labels + env `RES_BAKASU_NMD` aligned with the workflow (previously mismatched → the 2nd variant always showed as `skipped`)
+ ci: `.github/legacy/build.yml` `ln -sf resukisu drivers/kernelsu` block removed (BakaSU is in-tree, no symlink)
+ bakasu: sync upstream 4523 → **4529** (`main@d7260ca1`) — `KSU_VERSION` **35223 → 35229** (formula `30000 + rev-count + 700`)
+ bakasu: 3 kernel commits landed — rewrite `selinux_hide.c` (time side-channel fix, port tiann/KernelSU#3877), sucompat guard when ksud is absent (#597), `context_add_hash` sidtab (#623); 3 userspace commits (ksud cargo deps, manager translations) deliberately not synced
+ docs: skills `xxksu-*` → `bakasu-{integration,version-management,latest-check}`; AGENTS.md + README follow; add the **"manager rejects the kernel"** gotcha

> ⚠️ **Manager:** `KSU_VERSION=35229` must be covered by the manager APK's
> versionCode. The old manager `me.weishu.kernelsu` v3.3.0-70 (`32671`) sits far
> below that → it will be rejected with *"manager needs update"*. The BakaSU
> manager itself is nightly/WIP only (no GitHub Release). Details: `docs/issues/0008`.

## 2026-10-11 — Multibuild 4 Variants (xxKSU/BakaSU × NoMount) + Automatic Releases

+ ci: multibuild 4 variants per push (xxksu-nomount, xxksu, bakasu-nomount, bakasu) — separate sequential jobs (prepare → 4 builds → release)
+ ci: automatic release to `naidrahiqa/selene-releases` named `R##` (sequence via API); the same tag is used in the zip names and the release, shared across all variants
+ ci: Build Statistics per variant (duration + md5) in the step summary, release notes, and Telegram notifications; 1 variant failing = release skipped + per-job status notification
+ ci: kit enhancement — `config_overrides` input to toggle Kconfig per variant
+ bakasu: import BakaSU v4.2.0-rc3 (KSU_VERSION 35223) into `drivers/bakasu/`
+ bakasu: port hostsredirect (CONFIG_KSU_HOSTSREDIRECT) from xxKSU/FolkSU
+ bakasu: Kconfig choice ROOT_SOLUTION (KSU_XXKSU / KSU_BAKASU) in `drivers/Kconfig`
+ bakasu: conditional build via `drivers/Makefile` (obj-$(CONFIG_KSU_XXKSU) / obj-$(CONFIG_KSU_BAKASU))
+ scripts: `check-bakasu.sh` — upstream version check mirroring `check-xxksu.sh`
+ zip naming: `PawwwNunungggg-{variant}-{R##}-{sha7}-{YYYYMMDD}.zip`

## 2026-10-09 — FolkSU Integration & xxKSU Hosts Redirect

+ folksu: migrate root driver from ReSukiSU to FolkSU (LyraVoid/FolkSU@master, v0.1.0-pre6, KSU_VERSION 32742) in manual hook mode
+ xxksu: cherry-pick CONFIG_KSU_HOSTSREDIRECT — in-kernel systemless /system/etc/hosts redirection to /data/adb/hosts for bindhosts mode 3 / AdAway
+ folksu: add FolkSU release key and xxKSU manager key to multi-manager verification table
+ ci: update Telegram release notifications to provide FolkSU Manager APK, NoMount v20, and kernel zip download links
+ scripts: provide scripts/check-folksu.sh and update generate-ksu-notes.sh for FolkSU version management

## 2026-10-04 — ADIOS Hardening, ReSukiSU Sync & ZRAM Default

- mm/sched: revert schedutil rate limits and vm cache tweaks (vfs_cache_pressure, extra_free_kbytes) — caused lag in daily use, A/B verified
+ block: default zram disksize at boot to min(75% total RAM, 4GB) — 6GB unit gets 4GB, 4GB unit gets ~2.7GB; vendor fstab zramsize write now hits EBUSY and is ignored, kernel value wins
+ block: harden ADIOS against request loss — drain plug list when rd pool exhausted instead of requeue+break
+ block: fall back to priority queue when dl_group allocation fails during merge, no more orphaned requests
+ block: track in-flight ownership with rd->counted and add missing .requeue_request hook (fixes MMC requeue leak that stalls batch refill)
+ block: give each latency model its own aggregation buckets, reset under its own update_lock
+ block: clamp batch_limit, lat_target, and global_latency_window sysfs stores against truncation/overflow
+ resukisu: sync upstream to v4.2.0-rc3 (commit 4c5c8ce, KSU_VERSION 35202) — avtab removal length & xperms fix

## 2026-10-03 — Hardware KCAL, vm.swappiness 200, Dynamic Fsync & Boeffla WL Blocker

+ display: implement MediaTek hardware-accelerated KCAL color control (/sys/devices/platform/kcal_ctrl.0/kcal)
+ mm: allow vm.swappiness up to 200 for aggressive ZRAM swapping
+ power: pre-populate default blocked wakelocks (wlan_ipa, wlan_pno_wl, NETLINK) in Boeffla WL blocker
+ fs: implement Dynamic Fsync 2.0 (bypass fsync while screen on to eliminate I/O lag in MLBB/gaming)
+ power: add Boeffla generic wakelock blocker for MTK modem & Wi-Fi idle sleep drain
+ netfilter: enable xt_HL target (TTL/HL mangling support for tethering bypass)
+ tcp: enable TCP Westwood+ congestion control for unstable mobile connections
+ resukisu: sync upstream to v4.2.0-rc3 (commit 80c0e19, KSU_VERSION 35199)
+ drivers: expose display status via /proc/disp_state & enable DSI ESD check
Note: Hardware KCAL supports RGB gain via /sys/devices/platform/kcal_ctrl.0/kcal (compatible with Franco Kernel Manager). Recommended Zygisk module: Rezygisk/Brezygisk.

## 2026-09-27 — Fast Charge Bypass & Scheduler Tuning

+ mtk_charger: bypass thermal HAL limitation clamp (thermal_icl_ua = -1), boost charging to 10W+
- mtk_cooler_backlight: prevent thermal HAL from dimming or turning off LCD panel
+ block: switch default I/O elevator to mq-deadline for eMMC 5.1
+ net: set BBR as default TCP congestion control
+ net: enable QoS qdiscs (CAKE, FQ_CODEL, NETEM)
- ci: remove untested zip broadcast, streamline build notifications

## 2026-09-26 — Upstream lineage-24.0 Sync & Partition Safety

- anykernel: completely remove LK & DTBO flashing logic (strictly flash boot image only)
+ upstream: rebase to lineage-24.0 with CIP 4.19.325 sync
+ nomount: update to NoMount v20 with keyring-based redirection
+ power: enable USB Power Delivery & dual-charger support ala stock
+ camera: restore missing imx355 ultrawide sensor driver

## 2026-09-23 — Boot Stability, Panic Guards & Hardening

+ clk-mt6768: bounded loop for SPM ACK clock spins (fix MTCMOS boot hang)
+ scp: add bounded wait loop and release mutex on timeout (fix SCP IPI deadlock)
+ power/pmic/cmdq/leds: add NULL pointer checks and panic guards
+ arm64: implement clone3 syscall for Android 14-17 Bionic compatibility
+ defconfig: enable CONFIG_COMPAT=y for 32-bit apps and legacy vendor HALs
- dts: restore safe voltage/current limits in selene.dts to prevent brick risk

## 2026-09-19 — Initial Bringup

+ root: integrate ReSukiSU non-GKI manual hook mode
+ systemless: integrate NoMount path redirection
+ base: Linux 4.19.325 CIP LTS for MT6768 / MT6769 (Helio G88)
