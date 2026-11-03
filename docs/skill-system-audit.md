# Audit Sistem Skill & Repo Kernel Selene — 24 Oktober 2026

Laporan audit baca-saja sebagai dasar pembangunan sistem skill engineering.
Hasil penulisan file skill TENTUNYA tercatat di bagian akhir. Kategori: **VERIFIED** =
didukung output/source/git; **INFERRED** = didukung bukti tapi belum tuntas; **UNKNOWN** =
bukti tidak cukup.

## 1. Identitas repo (VERIFIED)

| Item | Nilai | Bukti |
|---|---|---|
| Kernel | Linux **4.19.325** (`VERSION=4 PATCHLEVEL=19 SUBLEVEL=325`) | `grep Makefile` |
| Localversion | `localversion-cip`=`-cip136`, `localversion-st`=`-st20` | `cat localversion*` |
| Arsitektur | ARM64/AArch64, toolchain Clang | `arch/arm64/`, `LLVM=1 LLVM_IAS=1` |
| Branch aktif | `EsTehAnget24.0` (tracking origin) | `git branch --show-current` |
| Shallow | `true` — history boundary; git log bisa menampilkan commit import sebagai "nambah file" | `rev-parse --is-shallow-repository` |
| Remote | 4 remotes (cip, creativchic, origin, upstream — semua https publik) | `git remote -v` |
| Branch lain | EsTehAnget-HyperOS, backup-m24-pre-sync, lineage-24.0, lsm-4.19-oneui, migrate-xxksu-driver | `git branch` |
| Stash | WIP `lsm-4.19-oneui` (selene.config + kernelsu Kbuild + mediatek Makefiles) | `git stash list` |
| Worktree | 2 folder 1 repo (k419 = 24.0; estehanget-hyperos = HyperOS) — refs dibagi | skill k419-workspace + git |

## 2. Build environment (VERIFIED sebagian besar)

- Defconfig target: **`selene_defconfig`** (`arch/arm64/configs/`); tidak ada defconfig device lain yang match selene.
- Toolchain: **Greenforce Clang 24.0.0** (`bf-clang-24.0.0-20261024`, LLVM commit `bb87bbed...`) terpasang di **kedua worktree**; guard `scripts/check-toolchain.sh` (file untracked).
- Out dir k419: regen defconfig berhasil hari ini dengan banner Cirrus 24.0.0; **sebelumnya** banner `out/.config` = clang 22.1.8 (system clang) — indikasi build terakhir fallback system clang.
- full-build terakhir dengan clang baru: ** BELUM dijalankan** (hanya regen defconfig + `init/main.o`).
- Kbuild notes: host tool (`scripts/kallsyms`, `sortextable`, ...) saat ini sudah build clean dengan hostgcc.

## 3. Lineage & backport yang dapat dipercaya (VERIFIED in-tree)

- `mm->mmap_lock` — rename 5.8 telah backported (`include/linux/mm.h` punya `mmap_lock`, tidak pakai `mmap_sem`).
- xarray `xa_*` termasuk `xa_is_value` — ada (2 trex di `include/linux/xarray.h`); tapi bagian xarray yang lebih baru 5.x TIDAK otomatis.
- Vendor code dari SMT MTK, Plus driver BakaSU (in-tree), NoMount, Kaeru — pengetahuan hardware ada di `.opencode/skills/mt6768-kernel/`.
- Lineage asli sebelum rebase — **UNKNOWN**; baseline "stabil" user = konteks, bukan generator, tidak bisa di-rekonstruksi dari git history shallow.

## 4. Fasilitas debug yang tersedia (VERIFIED dari `out/.config`, status 24 Oct)

| Config | State |
|---|---|
| `CONFIG_DEBUG_INFO=y` + `CONFIG_FRAME_POINTER=y` | on — addr2line stack works |
| `CONFIG_TRACEPOINTS=y` | on |
| `CONFIG_FTRACE=y` | on (cek DYNAMIC_FTRACE saay dipakai) |
| `CONFIG_KFENCE=y` | **on** — dan impl in-tree di `mm/kfence/` (core.c, report.c, kfence_test.c); `selene_defconfig` set `SAMPLE_INTERVAL=500 NUM_OBJECTS=63` |
| `CONFIG_KASAN` / `CONFIG_PROVE_LOCKING` / `CONFIG_SLUB_DEBUG` | **not set** — deteksi runtime berat tidak tersedia |
| `DEBUG_INFO_REDUCED` / `_SPLIT` / BTF | not set (buka full vmlinux debug info) |

Util pendukung: `scripts/grab-logs.sh`, `scripts/triage-pstore.sh`, issue trail `docs/issues/NNNN-*.md`.

## 5. Situasi Android integration (VERIFIED ringkas)

- DTS di `arch/arm64/boot/dts/mediatek/` — meskipun file per-device detail tidak dienum di audit ini; pengetahuan peta hardware/sensor/camera ada di `mt6768-kernel`.
- Packaging: AnyKernel3 atau device flash — terjaga oleh kernel-ci-kit (repo pisah); ATURAN: **JANGAN** flash LK/DTBO dari AnyKernel3 (brick).
- BakaSU + NoMount + versi manager terikat; Manager APK wajib versionCode >= 35229 (tercatat issues 0008). Gunakan skill detail: `bakasu-integration`, `nomount`.

## 6. State skill sebelum / sesudah build

**Sebelum (VERIFIED `ls`):** 30 SKILL.md di `.opencode/skills/` — format YAML frontmatter (`name`, `description`) + dokumen; seluruh `.opencode/` gitignored (aset lokal, tidak dipakai repo).

**Ditambahkan (NEW, 24 Okt 2026):**
- `.opencode/skills/android-kernel-engineering/` — SKILL.md (master workflow), CHECKLISTS.md, EXAMPLE-MEMORY-BUG.md
- `.opencode/skills/kernel-memory/` — lifetime/ownership/RCU/DMA
- `.opencode/skills/arm64-kernel/` — arch internals 4.19 selene
- `.opencode/skills/android-kernel-porting/` — metodologi antar-tree (incl. tracked rename `mmap_lock`, xarray, FS18XX)
- `.opencode/skills/kernel-debugging/` — silent-bug methodology + instrumen VERIFIED
- `.opencode/skills/kernel-git-discipline/` — rebase/reset/revert/bisect/worktree di repo SHALLOW
- `docs/skill-system-audit.md` (file ini)
- AGENTS.md: baris tabel routing + klarifikasi urutan (gitignored; efek bare-in)

### Gap map (skill yang diminta vs resolusi)

| Diminta | Resolusi | Catatan |
|---|---|---|
| master `android-kernel-engineering` | **DIBUAT** | lapisan prosedur — tidak menyalin AGENTS.md / mt6768-kernel |
| `kernel-c` | **ROUTED** ke `kernel-c-idioms` (+error-paths, locking) | sudah eksisting; tidak diduplikasi |
| `kernel-memory` | **DIBUAT** | gap nyata (lifetime/RCU/refcount methodology) |
| `arm64-kernel` | **DIBUAT** | tidak ada skill arch-level sebelumnya |
| `android-kernel-porting` | **DIBUAT** | metodologi antar-tree; prosedur cherry-pik khusus di patch-sync |
| `kernel-build-toolchain` | **ROUTED** ke build-local-test + build-system-fixes + defconfig-management | sudah diancang pas oleh 3 skill ini |
| `kernel-debugging` | **DIBUAT** | miss metodologi silent/intermiten; bukan pstore triage (crash-triage tetap) |
| `kernel-git-discipline` | **DIBUAT** | khusus safety rebase/reset/bisect/worktree di repo shallow |
| `kernel-performance` | **ROUTED** ke tuning-guard + battery-drain + kali data tuning di AGENTS.md | sudah eksisting |
| global agent rules | **AGENTS.md** (verified: gitignored, OpenCode membaca) | tambahan additif usulan: tabel skill + urutan kerja |
| checklists | **DIBUAT** di `CHECKLISTS.md` | 8 checklist sesuai deliverable E |
| contoh workflow | **DIBUAT** di `EXAMPLE-MEMORY-BUG.md` | fiktif, diberi label eksplisit |

## 7. Unknowns & risiko integrasi

- Menginstall inventori debug (KASAN/lockdep) memerlukan build vendor patch yang belum diketahui; jangan diasumsikan kompatibel.
- KFENCE in-tree masih belum diuji boot di hardware (config y + impl ada = VERIFIED tersedia; efek runtime UNKNOWN — dipakai best-effort, bukti via dmesg).
- HyperOS worktree **tidak punya** .opencode/skills sendiri — copy folder `.opencode/skills/*` bila akan bekerja di sana.
- `scripts/check-toolchain.sh` untracked — bila berpindah mesin, perlu re-add manual (AGENTS.md bergantung di sana).
- tree ini tidak boleh force-push, reset hard tanpa approval user (all worktree-share refs).
- untuk bisect lintas boundary shallow: hanya forward-test path; tidak bisa clone langsung dengan depth.

## 8. Ringkasan lintas-repo

Silakan baca `.opencode/skills/android-kernel-engineering/SKILL.md` sebagai titik masuk — tubuh referensi semua subskill di sini, instrumen, metode review, dan panduan valig.

## Addendum — 24 Okt 2026 (setelah kampanye selesai)

Beberapa catatan point-in-time di atas sudah terbasahi hasil hari yang sama:

- Full build dengan Clang 24.0.0 **lulus**: MAKE_EXIT=0, `Image.gz-dtb`
  12,4 MB (SHA `59a7657f…`). Pernyataan §2 "BELUM dijalankan" tidak berlaku
  lagi. Regen defconfig dengan toolchain benar menghasilkan **nol delta
  fungsional** — delta cuma 4 simbol fingerprint (CLANG_VERSION
  220108 → 240000); banner 22.1.8 di §2 sudah tidak ada.
- Dipakat AK3 rev2 (blok `install_fuse_storage_fix` dikeluarkan atas
  keputusan pemilik — FUSE-BPF drop), push → ReSukiSU Manager → flash →
  boot terverifikasi di selene `65cb03c00702`: banner
  `Cirrus clang 24.0.0 … #6 SMP PREEMPT Sat Oct 24 13:50:15 WIB 2026`,
  root `u:r:ksu:s0`, config kunci (KSU/MANUAL_HOOK/HOSTSREDIRECT/NOMOUNT)
  `=y` di `/proc/config.gz`.
- `scripts/check-toolchain.sh` kini **ter-track git** (commit
  `1e88b22bcb411503d1da80495acf35f1308531e8`) — unknown §7 "re-add manual bila pindah mesin" tidak
  berlaku lagi.
