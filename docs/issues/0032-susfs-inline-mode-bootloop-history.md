---
id: 0032
title: "SUSFS inline hook mode bootloop dua kali (29 Sep & 9 Okt 2026) — root cause UNKNOWN, mode dibuang permanen"
status: wontfix
severity: high
area: fs
opened: 2026-10-24
updated: 2026-10-24
fix_commit: ""
verified_on: ""
tags: [susfs, bootloop, history, vfs-hook, folksu, resukisu]
related: []
---

## Issue

SUSFS mode (`CONFIG_KSU_SUSFS`, "inline hook mode") pernah diintegrasikan
dua kali pada cabang samping dan **keduanya bootloop** dengan gejala
identik: layar logo Redmi → reboot, adbd tidak hidup, tidak ada log yang
bisa ditangkap. Penyebab mekanistis tidak pernah ketemu.

Catatan sejarah + klasifikasi: SUSFS **tidak pernah masuk** ke
`EsTehAnget24.0` HEAD — semua percobaan hidupnya di cabang samping
(`migrate-xxksu-driver` dan `lsm-4.19-oneui`, diverifikasi
`git merge-base --is-ancestor`). Basis integrasinya patch
SUSFS 2.3.0 de-inlined (`4a097e8d72f6`, tersimpan sebagai
`upstream/ksu-patches:patches/0002-SUSFS-2.3.0-Deinlined.patch`).

## Evidence

### Kampanye 1 — ReSukiSU susfs inline hook (Sep 2026, `migrate-xxksu-driver`)

| Commit | Tanggal | Arti |
|---|---|---|
| `789722ab9a06` | (sebelum 29 Sep) | sync fragment selene + disable KSU_SUSFS unported |
| `8be44999e273` | (sebelum 29 Sep) | enable SUSFS 2.3.0 via ReSukiSU susfs inline hook |
| `ddc87c2d6979` | 29 Sep 09:20 | tambah **7 kernel source hook site** (`ksu_handle_setresuid/execveat/faccessat/sys_read/stat/sys_reboot/input_handle_event`) supaya lolos `inline_hook_check.mk` |
| `0995e5c1eec8` | 29 Sep | gate init.rc stat spoof pada `CONFIG_KSU` (bukan manual hook) |
| `aa7b2572ba21` | 29 Sep | CI diubah mewajibkan SUSFS di critical config |
| `06ad3727f551` | 29 Sep 19:26 | **boot bisect**: `CONFIG_KSU_SUSFS=y` ditahan, SEMUA 9 subfeature dimatikan → **masih bootloop** |
| `e34f5e4a7558` | 29 Sep 19:54 | drop hook mode, kembalikan MANUAL_HOOK — verdict: regresi ada di mode (bukan subfeature); ReSukiSU docs menyebut susfs butuh backport gki-android12-5.10 yang tak terawat |
| `32041a369804` | 29 Sep 20:11 | drop kernel side (revert patch `4a097e8d72f6`); manual hook sites tetap |
| `273691bb2465` | 29 Sep 20:22 | buang 3 susfs-era call site (read/input/setresuid) — run CI `e34f5e4` sempat gagal link: simbol `ksu_is_init_rc_hook_enabled`/`ksu_is_input_hook_enabled` hanya hidup di branch susfs driver yang **tidak pernah dikompilasi**; known-good manual-hook build `g158222928f02` tidak punya call site ini |

### Kampanye 2 — FolksSU + NoMount v2.1.0 (9 Okt 2026, cabang yang sama)

| Commit | Tanggal | Arti |
|---|---|---|
| `b9da77224221` | 9 Okt 19:48 | integrate SUSFS 2.3.0 dengan FolksSU + NoMount v2.1.0 (21 file; `fs/susfs.c` 1561 baris; `fs/namei.c` +255; `fs/namespace.c` +244; `fs/proc_namespace.c` +182; `fs/readdir.c` +199)| 
| `c3d244ac366f` | 9 Okt 20:27 | drop lagi — pesan tanpa body, tidak ada log |

Defconfig tepat sebelum drop ini (`c3d244ac366f^`, dibaca 24 Okt 2026):
`CONFIG_KSU=y` + `MULTI_MANAGER_SUPPORT` + `HOSTSREDIRECT`,
`CONFIG_KSU_SUSFS=y` dengan **semua 9 subfeature ON**
(SUS_PATH, SUS_MOUNT, SUS_KSTAT, SPOOF_UNAME, ENABLE_LOG,
HIDE_KSU_SUSFS_SYMBOLS, SPOOF_CMDLINE_OR_BOOTCONFIG, OPEN_REDIRECT, SUS_MAP),
plus `CONFIG_TRACEPOINTS=y`.

### Cabang `lsm-4.19-oneui` — SUSFS masih tertanam sampai tip

`3d4fde1ff2b7` (8 Okt 21:23) "fs: Add SUSFS v2.3.0 (de-inlined)" adalah
komposisi penuh 21 file di cabang ini, di atasnya import KernelSU-Next
v3.4.0-legacy (`1ee7ec6ea3da`) + manual hooks (`fe1508a6c2aa`). Cabang ini
**tidak pernah menerima commit drop susfs** — `git grep -l susfs` di tip
masih menampilkan `fs/susfs.c`, `fs/namei.c`, `fs/namespace.c`, dkk.
Tidak ada bukti boot test di commit cabang ini.

Referensi lain yang sempat dianggap bagian sejarah: `695d5c5f43a4`
(18 Okt 2026, "kernel: Implemented SUSFS 2.3.0 [De-Inlined]") — tanggalnya
**setelah** kedua kampanye dan bukan ancestor cabang `migrate-xxksu-driver`
maupun `lsm-4.19-oneui`; asal-usul (remote referensi?) perlu dicek terpisah.

### Peta bukti yang menetapkan ruang lingkup

- Bootloop terjadi **baik dengan 9 subfeature ON** (kampanye 2) maupun
  **OFF** (bisect `06ad3727f551`) → trigger konstan di tingkat mode:
  call site inline + branch susfs driver + kernel-side code dasar.
- Manual-hook build selalu sehat dalam periode yang sama
  (known-good `g158222928f02`).
- Tidak ada pernapasan log: adbd mati; capture pstore yang sekarang siap
  (`PSTORE_RAM=y`) belum/tidak terpakai pada saat kejadian.

## Root cause

**TIDAK DIKETAHUI** (status mekanisme UNKNOWN). Yang tervalidasi hanya:
reproduksibilitas (2×), bahwa semua subfeature bukan penyebab, dan bahwa
config manual-hook normal.

 Diagnosis yang gugur:
- 9 subfeature bukan penyebab (bisect `06ad3727f551`).
- Bukan double-invocation manual+inline — known-good build manual tak punya
  call site itu (`273691bb2465`).

 Hipotesis yang belum terbantahkan (TIDAK TERBUKTI, urutan riset jika
 dibuka lagi):
1. Branch susfs di driver (kode ReSukiSU/FolksSU era, static keys
   `ksud_integration.c`) — kode ini **sudah tidak ada** di BakaSU 4536.
2. Interaksi 7 call site inline (`hak exec/stat/read/input` fase init
   awal) dengan gating `CONFIG_KSU` — adbd mati = kegagalan pre-service.
3. Kernel-side code dasar susfs (kthread sdcard monitor, `susfs_extra_works`,
   static keys di namei/namespace) yang jalan meski subfeature off —
   belum bisa disingkirkan mesin mati sebelum log.

Catatan kontradiksi dokumen (dua-duanya benar, domain beda):
patch `include/linux/susfs.h:13-15` mendeklarasikan varian NON-GKI untuk
kernel <5.0, sedangkan ReSukiSU docs menyebut butuh backport
`gki-android12-5.10` yang tak terawat — source-level vs perangkat-terbukti.

## Kenapa wontfix

1. Mekanisme hanya bisa ketemu lewat boot bertahap bertelingah pstore yang
   belum tersedia pada saat kejadian; mode sudah dibuang dua kali dan
   tidak ada kebutuhan fitur yang menggantung padanya.
2. Satu-satunya susfs kernel-side yang layak untuk 4.19 adalah patch
   de-inlined 2.3.0 ini — sementara BakaSU upstream rev 4536 secara
   eksplisit **menolak** mode susfs:
   `drivers/bakasu/tools/susfs_compat.mk:20` `$(error Please wait susfs update.)`
   (unconditional, setelah sniff fitur di line 5–16). Mengintegrasikan
   berarti melawan gating driver sendiri; Kbuild `drivers/bakasu/Kbuild:177-189`
   juga mewajibkan `fs/susfs.c` + membaca `SUSFS_VERSION`.
3. `inline_hook_check.mk` line 26–27 melarang kompat dengan susfs lama
   ("don't maintain ANY backward compatibility for old version of susfs") —
   driver menuntut kernel-side terbaru, sedangkan kernel-side terbaru yang
   tersedia untuk 4.19 hanya patch community de-inlined ini.
4. Kebutuhan concealment tidak diprioritaskan owner; NoMount 2.1 + manual
   hook + modul storage userspace sudah menutup kebutuhan saat ini.

## Kalau suatu hari dibuka lagi (syarat minimal, bukan panduan)

- Baseline manual hook tetap hidup; susfs hanya delta tambahan di branch
  eksperimen (`kernel-git-discipline`).
- PSP/pstore (`PSTORE_RAM=y` + `PSTORE_CONSOLE` + `PSTORE_PMSG`) harus
  terbukti bekerja dulu di build tanpa susfs, supaya satu boot gagal
  langsung meninggalkan log.
- Kernel-side code dasar dan driver mode dibedah satu-satu; 9 subfeature
  tetap OFF sampai mode dasar terbukti boot.
- Status issue ini di-naikkan ke `diagnosed` saat mekanisme ketemu;
  evidence yetep di skill `crash-triage` + `kernel-debugging`.
