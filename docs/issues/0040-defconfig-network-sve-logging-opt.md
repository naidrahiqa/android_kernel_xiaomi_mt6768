---
id: 0040
title: Optimasi defconfig jaringan (BBR/Westwood, TTL mangle), aktivasi Dynamic Fsync 2.0, dan eliminasi SVE check overhead
status: fixed-build-only
severity: medium
area: config
opened: 2026-11-07
updated: 2026-11-07
fix_commit: "d9121280cf23"
tags: [defconfig, bbr, westwood, sve, dynamic_fsync, netfilter, logspam]
related: [0034, 0038, 0039]
---

## Issue

Implementasi penyelarasan konfigurasi kernel lanjutan pada `selene_defconfig`:
1. **Jaringan & Throughput (TCP BBR + Westwood)**:
   - Mengaktifkan `CONFIG_TCP_CONG_BBR=y` dan `CONFIG_TCP_CONG_WESTWOOD=y`.
   - Menetapkan BBR sebagai algoritma congestion control bawaan (`CONFIG_DEFAULT_TCP_CONG="bbr"` / `CONFIG_DEFAULT_BBR=y`) untuk mengatasi bufferbloat dan memaksimalkan throughput pada jaringan seluler/Wi-Fi dengan loss tinggi.
   - Mengaktifkan `CONFIG_NETFILTER_XT_TARGET_HL=y` bersama `CONFIG_IP_NF_MANGLE=y` dan `CONFIG_IP6_NF_MANGLE=y` untuk mendukung manipulasi TTL/HL paket IP (tethering bypass).

2. **Aktivasi Dynamic Fsync 2.0**:
   - Menambahkan `CONFIG_DYNAMIC_FSYNC=y` pada `selene_defconfig` untuk mengaktifkan modul `fs/dynamic_fsync.c` secara default.

3. **Eliminasi Overhead CPU (SVE Check)**:
   - Menetapkan `# CONFIG_ARM64_SVE is not set`. MediaTek MT6768 (Cortex-A75 + Cortex-A55) tidak mendukung Scalable Vector Extensions (SVE). Menghilangkan opsi ini menghemat siklus CPU yang sebelumnya dihabiskan untuk menangani trap dan context-switching SVE.

4. **Pembersihan Log Noise Vendor**:
   - Menonaktifkan logging berlebih: `# CONFIG_MTK_CONNSYS_DEDICATED_LOG_PATH is not set`, menghapus `CONFIG_MTK_GZ_LOG=y`, `CONFIG_HAVE_MTK_GZ_LOG=y`, dan `CONFIG_MTK_MRDUMP_KEY=y` untuk menghemat memori runtime dan mengurangi kebisingan log dmesg.

## Verification

- `selene_defconfig` diregenerasi dan diverifikasi:
  - `CONFIG_CLANG_VERSION=240000`
  - `# CONFIG_ARM64_SVE is not set`
  - `CONFIG_DEFAULT_TCP_CONG="bbr"`
  - `CONFIG_DYNAMIC_FSYNC=y`
  - `CONFIG_NETFILTER_XT_TARGET_HL=y`
- Build lokal berhasil dengan Greenforce Clang 24.0.0 (`MAKE_EXIT=0`, `Image.gz-dtb` 12MB).
- Paket AnyKernel3 dibuat: `dist/EsTehAnget-d912128-071126.zip` (SHA256: `8ed3ae51adf04a1950ba80175651491a86ff6c6e0446d8b1f7a751ea98380461`).
