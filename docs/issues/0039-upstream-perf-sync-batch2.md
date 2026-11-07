---
id: 0039
title: Sync Batch 2 optimasi performa, scheduler, dan daya dari upstream/lineage-24.0-perf (19 commits)
status: fixed-build-only
severity: medium
area: perf
opened: 2026-11-07
updated: 2026-11-07
fix_commit: "0fbc9dd768aa aa64d99154f1 b5757fcbf98c c64a471b947a 79207ce33b85 b1af7f35abfd eab1f98bb4e9 40b94f413815 185fb73bac4f ccf5db73cf7f 16ca3f62d714 48c0ce974bdd 8f62de06796a 5ff608ae8444 3c12d469aca3 9094cfbb79cb ea5568d77f60 ef652be0cba4 d48172d6cd92"
tags: [perf, scheduler, power, rcu, dma, build, sync]
related: [0034, 0036, 0038]
---

## Issue

Melanjutkan audit antrean optimasi performa dari `upstream/lineage-24.0-perf`.
Batch 2 mengintegrasikan 19 commits yang berfokus pada:
1. **Memory & I/O Overhead Reduction:**
   - `0fbc9dd768aa`: `lib/scatterlist.c` mengalihkan alokasi sg list dari `__get_free_page()` lambat ke slab allocator `kmalloc()` (benchmark membuktikan alokasi 9us turun ke 4us).
   - `185fb73bac4f`: `dma-buf/sync_file` memotong alokasi/duplikasi debug string names pada sync file ioctl (`sync_file_ioctl_fence_info`), mempercepat rendering antarmuka grafis Android.
   - `b1af7f35abfd`: `power_supply_sysfs.c` tidak lagi mengalokasikan memori dinamis di heap (`kstruprdup`) saat query uevent healthd; menggunakan stack buffer `char attrname[64]`.
   - `40b94f413815`: fix memory leak pada `dma_async_device_register` error path.

2. **Scheduler & Execution Optimization:**
   - `3c12d469aca3`: `sched/fair` hindari menarik task dari CPU dengan `nr_running <= 1` saat load balance, memperbaiki spreading utilisasi CPU octacore secara signifikan (sysbench max latency turun 41ms -> 21ms).
   - `8f62de06796a`: `sysctl_sched_nr_migrate = NR_CPUS` (dinamis mengikuti jumlah core CPU alih-alih angka konstan 32), mengurangi jitter dan latensi pada RT/FIFO tasks saat IRQs disabled.
   - `16ca3f62d714` & `48c0ce974bdd`: tambahkan `unlikely()` hints pada syscall `kcmp` dan `mincore` boundary checks.

3. **Power Management & Suspend:**
   - `9094cfbb79cb`: cegah userspace membatasi CPU idle states lewat pm_qos requests, mencegah pemborosan daya tak perlu.
   - `c64a471b947a`: jangan mematikan CPU idling (`cpuidle_pause`/`cpuidle_resume`) selama proses suspend noirq; biarkan CPU idle saat device tidur panjang.
   - `5ff608ae8444`: jangan disable/enable OOM killer saat suspend/resume jika dikompilasi untuk Android (karena Android mengelola LMK sendiri).
   - `b5757fcbf98c`: letakkan statistik wakeup di `/sys/devices/virtual/wakeup` agar SELinux Android dapat membacanya secara seragam tanpa bentrok label hardware.
   - `79207ce33b85`: MTK video `disp_lowpower` gunakan `sched_clock()` dan perbaiki perhitungan interval timer `idlemgr`.

4. **RCU & Compiler Optimizations:**
   - `eab1f98bb4e9`: RCU priority boost kthreads gunakan `schedule_timeout_idle()` alih-alih `schedule_timeout_interruptible()` agar tidak menggelembungkan load average sistem.
   - `ccf5db73cf7f`: jalankan RCU preempt boost segera (`boost_time = jiffies`) tanpa delay tambahan untuk interaktivitas instan.
   - `aa64d99154f1`: hapus `-mllvm -import-instr-limit=5` pada ThinLTO Makefile, memulihkan inlining cross-TU yang terhambat batas sempit.
   - `ea5568d77f60`, `ef652be0cba4`, `d48172d6cd92`: nonaktifkan init1 stress test pada MTK EEM serta kompilasi modul tes/debug pada DRAMC dan MFD MT6358 untuk non-eng builds.

## Verification

- Semua 19 commits di-pick bersih di branch `EsTehAnget24.0` hingga commit `d48172d6cd92`.
- Verifikasi kompilasi lokal via Greenforce Clang 24.0.0 (`CONFIG_CLANG_VERSION=240000`, `selene_defconfig`):
  - `Image.gz-dtb` dihasilkan sukses (12MB, MAKE_EXIT=0).
- Dipaketkan ke AnyKernel3 flashable zip: `dist/EsTehAnget-02320d7-071126.zip` (SHA256: `5fc71e284f27380ded2dcf68fb88562956c91372a19de55bfc63ce0a201f4485`).
- Pushed to device at `/sdcard/Download/EsTehAnget-02320d7-071126.zip` (checksum verified). Siap diuji di hardware.

