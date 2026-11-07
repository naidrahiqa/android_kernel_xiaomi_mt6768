---
id: 0038
title: Sync Batch 1 optimasi performa dan stabilitas dari upstream/lineage-24.0-perf (22 commits)
status: fixed-build-only
severity: medium
area: perf
opened: 2026-11-07
updated: 2026-11-07
fix_commit: "62bbdbd2727c d8bd3cdf8c45 363e34a75533 5d0d43a8f2e6 d5cf7b08faca 2e9c19aa2685 b5e6d0b7dc32 3dbb74b70335 44379503f0b2 6e4c1b20443b 698f6ce7275c 5abc4bc7ea8b 5e59a9704bb1 727a5785b92d e43250788dc9 cb478cbd6383 4f554e50ea32 826d4012a3be e6053e6fa902 8dc4493bf5f6 61f32878fde8 7ccb46140cdf"
tags: [perf, mmc, arm64, xanmod, block, power, media, sync]
related: [0034, 0036]
---

## Issue

Antrean 87 patch performa dari `upstream/lineage-24.0-perf` dievaluasi untuk
meningkatkan responsivitas UI, latensi I/O, dan efisiensi daya pada Xiaomi Selene (MT6768).

Batch 1 mengambil 22 patch prioritas tinggi yang mencakup:
1. **MMC & Driver Safety:**
   - `62bbdbd2727c`: mematikan kompilasi `mtk-sd-dbg.c` untuk mencegah potensi spinlock hang dan memangkas overhead interrupt MMC.
   - `d5cf7b08faca`: fix Bad SLAB free kernel panic pada `spi_slave` teardown (static struct dibebaskan via kfree).
   - Pengurangan overhead logging pada video driver, camera ISP, dan cmdqv3 tests.
2. **Core Arm64 Speedup:**
   - `b5e6d0b7dc32`: import implementasi `memcpy()` / `memmove()` arm64 terbaru dari ARM optimized-routines.
   - `2e9c19aa2685`: align `strcmp`/`strncmp` ke 64-byte cache line untuk mengurangi cache line split stalls.
   - `3dbb74b70335`: stub debug prints pada binder untuk mempercepat inter-process communication Android.
3. **Storage & Block I/O (Xanmod):**
   - `44379503f0b2`: `rq_affinity` untuk multithreaded I/O requests.
   - `6e4c1b20443b` & `698f6ce7275c`: tuning sequential request & disable front_merges pada `mq-deadline`.
4. **Power & Wakeup Management:**
   - `5abc4bc7ea8b` & `5e59a9704bb1`: minimalkan wakeup time pada alarmtimer dan hindari excessive s2idle wakeup attempts.
   - `8dc4493bf5f6` & `61f32878fde8`: pasang `WQ_POWER_EFFICIENT` pada workqueue scp logger dan mtk vibrator.
   - `7ccb46140cdf`: increase ratelimit pages value untuk mengurangi frekuensi blocking page writeback checks.

## Verification

- Semua 22 patch lolos cherry-pick bersih tanpa git conflict.
- Toolchain: Greenforce Clang 24.0.0 (`CONFIG_CLANG_VERSION=240000`).
- Local build compilation test berjalan via `make -j$(nproc) selene_defconfig`.
