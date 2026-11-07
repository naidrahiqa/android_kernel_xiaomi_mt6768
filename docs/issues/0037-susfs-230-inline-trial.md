---
id: 0037
title: "SUSFS 2.3.0 inline mode trial (BakaSU combo) bootloop di selene hardware — status wontfix"
status: wontfix
severity: high
area: fs
opened: 2026-11-07
updated: 2026-11-07
fix_commit: ""
verified_on: ""
tags: [susfs, bootloop, trial, bakasu, inline-hook, vfs]
related: [0032]
---

## Issue

Kelanjutan history SUSFS: `#0032` (SUSFS inline mode 2026-09/10 → bootloop, dibuang permanen).
Trial sekarang beda setup:

| | 0032 (dulu) | trial sekarang |
|---|---|---|
| driver | simonpunk KSU/xxKSU | **BakaSU** (in-tree `drivers/bakasu/`) |
| mode | KSU_SUSFS subsystem (inline, VFS mount namespace) | hooking-method choice `CONFIG_KSU_SUSFS` + subfitur OFF dulu |
| defconfig | semua fitur | 9 subfitur eksplisit `is not set` |

## Approach

SUSFS 2.3.0 **de-inlined** patch (`upstream/ksu-patches:patches/0002-SUSFS-2.3.0-Deinlined.patch`,
port per-hunk): simbol Kconfig asli (`CONFIG_KSU_SUSFS*`) bukan ccflags injeksi driver.
BakaSU memvalidasi integrasi saat build via `tools/inline_hook_check.mk`.

Commits (branch susfs-trial-20261107):

| Commit | Isi |
|---|---|
| `5a09fc0cda5b` | fs: integrate SUSFS 2.3.0 kernel side (de-inlined) |
| `6a772dfcbdd7` | kernel: add remaining BakaSU SUSFS inline-mode manual hooks |
| `db9a7bd36da6` | defconfig: switch KSU to SUSFS inline hook mode for trial |
| `188eb25040e1` | fs: split stat hooks between manual-hook and SUSFS modes |

## Cara pack zip AK3 secara lokal (yang bener, 2026-11-07)

**Jangan pakai `~/.local/bin/zip`** — itu shim Python yang strip prefix direktori
top-level (`META-INF/`, `tools/` hilang semua) → di-device installer langsung
failed. Machine nggak punya `/usr/bin/zip` asli. Tool yang valid: **`bsdtar`**
(`/usr/bin/bsdtar`) atau `7z`.

```sh
# 0. toolchain: export PATH=<worktree>/greenforce-clang/bin:$PATH (check-toolchain.sh)
#    build dari worktree k419, bukan folder acak
# 1. copy kernel fresh:
cp out/arch/arm64/boot/Image.gz-dtb ak3/Image.gz-dtb
# 2. pack dari dalam ak3/ (prefix ikut utuh):
cd ak3
rm -f ../dist/EsTehAnget-<tag>.zip
bsdtar -a -cf ../dist/EsTehAnget-<tag>.zip \
  META-INF anykernel.sh Image.gz-dtb tools patch ramdisk modules LICENSE
# 3. verify struktur MIRIP known-good ~/Downloads/EsTehAnget-selene-r15-imx355-uwfix.zip:
unzip -l ../dist/...   # wajib ada: META-INF/com/google/android/update-binary,
#                      tools/ak3-core.sh, patch/placeholder, modules/system/lib/modules/placeholder
unzip -t ../dist/...   # "No errors detected"
# 4. push + cek size on-device:
adb -s <serial> push ../dist/...zip /sdcard/Download/
adb -s <serial> shell ls -l /sdcard/Download/...zip   # size harus identik
```

**Struktur wajib di dalam zip** (pattern sukses):
`META-INF/com/google/android/{update-binary,updater-script}`, `anykernel.sh`,
`Image.gz-dtb`, `tools/{ak3-core.sh,busybox,fec,magiskboot,magiskpolicy,
lptools_static,httools_static,snapshotupdater_static}`, `patch/placeholder`,
`ramdisk/placeholder`, `modules/system/lib/modules/placeholder` (+ `LICENSE`).

**Hadits tetap:** zip HANYA berisi `boot` flash (`dump_boot`/`write_boot`) — tanpa
lk, dtbo, kaeru_selene.bin (brick risk).

**Keadaan ak3/ saat pack ini (belum di-commit!):** `anykernel.sh` = rewrite lokal
(device selene/merlin/lancelot + `BLOCK=auto`) **tanpa** blok
`install_fuse_storage_fix` (56 baris, berakhir `write_black_soldier;`? tidak —
`write_boot;`), `tools/fix-fuse-storage.sh` dihapus (untracked, cukup rm),
`Image.gz-dtb` untracked (staging). Commit ak3 nanti kalau mau didurab: konsep
tunggal `ak3: selene device config, drop obsolete fuse-storage fix`.

## Bootloop + rollback pasca flash pertama (2026-11-07 ~10:20)

- Flash zip hasil rebuild (tanpa storage-fix) → **bootloop**. Recovery nggak
  bisa dimasukin (adb di recovery gagal — "device not found").
- **Rescue**: flash `boot_a` via fastboot pakai build vendor lama
  `~/Downloads/Bahan GSI/dieD_vendor_v3.0_k419/boot.img` (64MB, fastboot aman,
  boot saja — bukan lk/dtbo) → `fastboot flash boot` OK, reboot.
- **Rollback kernel tree**: tag `backup/pre-susfs-revert-20261107` → `188eb25040e1`
  (4 commit trial SUSFS). `git reset --hard HEAD~4` → branch balik ke
  `073f2da0908e` = Batch C/D tanpa SUSFS. Build ulang manual di-jalanin
  background, log `/tmp/opencode/kernel-build-revert.log`.
- **Bukti pstore SUSFS crash**: begitu old kernel jalan, ramoops region masih
  pegang konsol 2 bootloop terakhir → tapi setelahnya bakal ditumpuk. Pull
  cepat pas old kernel boot. Kalau ketahapan `panic` lompat ke SUSFS commit
  → record root cause di file ini sebelum tutup trial.
- Status: `diagnosed-in-progress` (belum tahu root cause exact; susfs bare
  integration w/o subfeature gugur di early boot di hardware ini)

- `MAKE_EXIT=0`, `Image.gz-dtb` 12.4 MB, Greenforce Cirrus clang 24.0.0 (`CONFIG_CLANG_VERSION=240000`)
- Config kunci: `CONFIG_KSU_SUSFS=y`, `CONFIG_KSU_MANUAL_HOOK is not set`, 9 subfitur semua `is not set`
- BakaSU inline check: 7/7 hook found (`ksu_handle_{setresuid,execveat,faccessat,sys_read,stat,sys_reboot,input_handle_event}`), `SUSFS_VERSION: v2.3.0`
- Zip: `dist/EsTehAnget-SUSFS-188eb25-071126.zip` (15,409,594 b — rebuild 10:14, tanpa
  `fix-fuse-storage.sh`; push `/sdcard/Download/` device 65cb03c00702 terverifikasi)

## Gotcha yang ke-mukul (tidak terdokumentasi BakaSU)

1. Driver hanya export ret-hook stat (`ksu_handle_newfstat_ret`/`fstat64_ret`) di mode
   `CONFIG_KSU_MANUAL_HOOK`; mode SUSFS gantinya `ksu_handle_vfs_fstat(fd, &kstat.size)`
   → commit `188eb25040e1`.
2. Static-key guard `ksu_input_hook`/`ksu_init_rc_hook` tidak di-export di mode SUSFS
   (simbol terlarang di file hook; driver gate internal sendiri).
3. `fs/susfs.c` tidak menyebut driver `kernelsu/` sama sekali (de-inlined bersih).
4. **Pack zip: `~/.local/bin/zip` itu shim Python yang strip prefix direktori top-level**
   → `META-INF/` hilang, installer langsung failed ("formatnya apa dah"). Machine ini
   nggak punya `/usr/bin/zip` — pakai `bsdtar -a -cf` atau `7z a`.
5. Build trial ini `CONFIG_FUSE_BPF is not set` (`grep FUSE_BPF` nol hasil di Kconfig.default
   & defconfig) → FUSE BPF sudah di-drop dari kernel, jadi fix bind-mount
   `fix-fuse-storage.sh` basi. Blok `install_fuse_storage_fix` dibuang utuh dari
   `ak3/anykernel.sh` (file sekarang 56 baris, berhenti di `write_boot;`) — tanpa ini,
   fallback embedded heredoc tetap deploy script-nya walau file tools nggak ada di zip.
   Edit ak3/**belum** di-commit (sebelumnya juga uncommitted rewrite device config).

## Rollback path

- Branch ini sendiri; `EsTehAnget24.0` belum disentuh.
- Trial → revert `db9a7bd36da6` (+ optionally 6a77/188eb) manual-hook mode kembali utuh.
- Bootloop → pstore (`scripts/grab-logs.sh <label>`), lalu flash zip non-SUSFS terakhir.

## Langkah berikutnya

- [ ] Flash zip → boot test selene
- [ ] `grab-logs.sh susfs-trial-a`
- [ ] Kalau boot OK: aktifkan subfitur satu batch (SUS_PATH → SUS_MOUNT → dst), iterasi
- [ ] Kalau bootloop: catat evidence di file ini, revert trial, status `diagnosed/fixed?`
