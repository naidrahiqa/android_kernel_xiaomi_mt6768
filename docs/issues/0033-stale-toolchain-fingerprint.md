---
id: 0033
title: "Fingerprint toolchain menetap di out/.config (clang sistem 22.1.8 vs Greenforce 24.0.0) — build lokal salah toolchain tanpa satu error pun"
status: verified
severity: medium
area: build
opened: 2026-10-24
updated: 2026-10-24
fix_commit: "be5fb9bf29b5"
verified_on: "4.19.325-cip136-st20-EsTehAnget+ (banner #6 SMP PREEMPT Sat Oct 24 13:50:15 WIB 2026, selene 65cb03c00702)"
tags: [toolchain, clang, regen, fingerprint, greenforce, check-toolchain]
related: []
---

## Issue

`out/.config` baseline lama menyimpan fingerprint Kconfig toolchain dari
clang **sistem 22.1.8** (`CONFIG_CLANG_VERSION` dkk.), bukan Greenforce
Cirrus 24.0.0 — bukti regen/build terakhir di shell itu jatuh ke system
clang lewat fallback PATH. Build tetap hijau dan log bersih; PGO/Polly
hilang diam-diam, dan `.config` "resmi" membawa fingerprint toolchain
salah. Pola yang sama pernah nyangkut di HP 15 Okt 2026 (uname menulis
"Greenforce", banner nyata clang 22.1.8); 24 Okt 2026 ketahuan lagi
dari `.config` lama.

## Evidence

| Bukti | Nilai |
|---|---|
| `grep CONFIG_CLANG_VERSION out/.config` sebelum regen | `220108` (clang 22.1.8) |
| Hash config sebelum / sesudah regen | `a6fc2bcc…` → `4c2fd974…` |
| Delta simbol regen | **4 fingerprint saja**, nol delta fungsional |
| Regenerasi (fase 4) | MAKE_EXIT=0 |
| `/proc/version` pasca flash (65cb03c00702) | `Cirrus clang version 24.0.0 (…bb87bbed…), LLD 24.0.0` |

## Fix

1. **`scripts/check-toolchain.sh` (`be5fb9bf29b5`)** — exit 1 kalau
   `command -v clang` bukan `greenforce-clang/bin` milik worktree ini;
   banner wajib `Cirrus clang` (vendor string Greenforce). Jalankan di
   shell yang sama persis sebelum `make` apa pun, **termasuk regen
   defconfig**.
2. Skill `build-local-test`: PATH Greenforce wajib di-export sebelum
   regen (§2) + langkah checklist `grep '^CONFIG_CLANG_VERSION=240000'
   out/.config` (§4) — fingerprint simbol adalah bukti keduanya kala
   guard belum ada dan pasca regen.
3. Regenerasi ulang dengan env lengkap — hasil: fingerprint benar,
   simbol fungsional tak berubah (hash `4c2fd974…`).

## Verified

- Build penuh MAKE_EXIT=0; artifact `out/arch/arm64/boot/Image.gz-dtb`
  12,4 MB (SHA `59a7657f…`).
- Dipakat AK3 rev2 → push → flash via ReSukiSU Manager → boot
  `sys.boot_completed=1` (~100 s, normal).
- Banner in-kernel: `Cirrus clang version 24.0.0 …, LLD 24.0.0` +
  `#6 SMP PREEMPT Sat Oct 24 13:50:15 WIB 2026` — payload build 24 Okt,
  bukan baseline lama.
- `zcat /proc/config.gz`: `CONFIG_CC_IS_CLANG=y` + config kunci
  (KSU/MANUAL_HOOK/HOSTSREDIRECT/NOMOUNT) semua `=y`.

## Catatan

- Guard berbasis PATH tidak menutup satu celah: regen yang dijalankan di
  shell lain tanpa export anjuran tetap bisa lolos — itu sebabnya
  `CONFIG_CLANG_VERSION` di-checklist sebagai verifikasi layer kedua
  (skill `build-local-test` §4).
- Zsh jangan pakai env string (`KENV="..."`) — lihat gotcha
  `make O=out $KENV` di AGENTS.md.
