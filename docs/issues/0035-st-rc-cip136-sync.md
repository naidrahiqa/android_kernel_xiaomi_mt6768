---
id: 0035
title: Sync Batch C dari cip linux-4.19.y-st-rc ke EsTehAnget24.0 (20 patch net/security, clean-only)
status: fixed-build-only
severity: medium
area: net
opened: 2026-11-07
updated: 2026-11-07
fix_commit: "f39f457f8ad7 17c7e9dc9c4f ef4a9f83aa90 937f390809b0 a80405780bb1 434a019f03af 13cccd461412 5bb7cdac4708 94cb5049eb5d 6f6dfa810807 a9d30eda459c 907bda59cc83 f0b3534fa992 b9442a464b3b f8fb5acd25ca bf8776622050 b72d380a3ca3 89e5db03243e 9fdebeacbec0 a7269bc31e66"
tags: [st-rc, cip, sync, security, cherry-pick, batch-c]
related: [0034, 0029]
---

## Issue

`EsTehAnget24.0` berada di base `cip136` (`596368289cc3`) yang sama dengan
base `linux-4.19.y-st-rc` (`8e576a80184d`, `-st20`, up-to-date dengan
5.10.266). `st-rc` head `09c9317a3923` (2026-10-30) unggul 885 commit di atas
base itu (827 file, +6791/-3009), mayoritas tidak relevan untuk MT6768
(nouveau, x86, virtio, dsb).

Sync dilakukan bertahap per konsep, bukan mass-sync. Batch C = 20 patch
net/security yang apply bersih (forward-test lolos) — VERIFIED 812/885 apply
bersih, 73 conflict butuh port manual.

## Evidence

- Base sama: `git show HEAD:localversion-st` = `-st20`,
  `git show HEAD:localversion-cip` = `-cip136` (VERIFIED).
- `git log --oneline 8e576a80184d..FETCH_HEAD | wc -l` = 885 (VERIFIED).
- Forward-test per patch: `git show --binary <sha> | git apply --check`
  = 812 apply bersih, 73 conflict (VERIFIED 2026-11-07).

## Batch C (20, oldest-first, clean-only, relevan Selene)

```text
619b2a5f8ee5 Bluetooth: RFCOMM: fix NULL dereference of dlc->session in RFCOMM_CONNINFO
9ef244c12644 inet: frags: publish queues before arming timer
b29f321b9046 ipv6: mcast: Fix use-after-free when processing MLD queries
aeca4496f07b netfilter: nf_queue: pin bridge device while NFQUEUE holds fake dst
4fae216b4a17 tcp: fix potential race in tcp_v6_syn_recv_sock()
efff42e76259 tcp: clear sock_ops cb flags before force-closing a child socket
3f78220d000d xfrm6: fix out-of-bounds write in xfrm6_input_addr() when secpath is full
6434896a8822 wifi: mt76: mt76x02: do not WARN on invalid rx descriptor length
7a85d5bf3749 cpufreq: zero-initialize policy cpumask before sysfs publication
ad002df2ef43 ipv4: fib: bound automatic table ID allocation
cbf63e3778be netfilter: flowtable: hold reference on ct until flow is released
a27a4884b8c4 ipvs: revalidate ihl before icmp_send
b78ecf68a556 ipv6: sr: enforce exact attribute length for SEG6_ATTR_DST
1aef1ed67bf5 netfilter: ip6t_rt: fix zero-address non-strict match out-of-bounds read
efc263c2c0b1 wifi: libertas: reject short monitor TX frames
e081a6b83803 fou: Fix use-after-free in fou_create()
e37dae2a4576 net: lock the socket in sock_gettstamp()
28db7b5b3dfc ipv6: do not let ipv6_find_hdr() return an offset past the packet end
0f9dd2fd36dc ipv4: validate checksum_start before completing checksum
09c9317a3923 ipv4: free inet_opt and ireq_opt after an RCU grace period
```

Dikecualikan dari batch ini (conflict, port manual nanti):
`88588102ee3a bpf rtt_min OOB`, `3a1fe75c4db9 mm/swap fscrypt`,
`7983340f5727 cpufreq schedutil overflow`, `0eceef464ddb cpufreq rwsem`,
`92417a748a8d fuse flock`, `f9f6e27e2d07 f2fs inline dentry`,
`e13338659980 tcp_rmem`, `5b5b707281db lwt_bpf`.

## Fix

`git cherry-pick -x` per commit (1 konsep = 1 commit), urutan topo
oldest-first. Backup sebelum pick:
`backup/pre-st-rc-pick-20261107` @ `1aa55aa0ca5e`.

Metode aktual: 8 commit pertama via `cherry-pick -x`, sisanya (termasuk
`7a85d5bf3749 cpufreq`) via `git show --binary <sha> | git apply --index`
+ commit dengan body asli + `(cherry picked from commit ...)` footer —
`cherry-pick` 3-way merge conflict di `drivers/cpufreq/cpufreq.c` karena
tree lokal diverge berat (555 insertions vs parent st-rc), padahal
forward-test `git apply --check` bersih.

Hasil: 20 commit baru di atas `f3f34198f3e7` (docs issue 0035), total
21 commit di atas `1aa55aa0ca5e`, 40 file (+346/-111), footers 20/20.

## Verification

- [x] `git log` 21 commit baru di atas `1aa55aa0ca5e`, status clean (VERIFIED)
- [x] `scripts/check-toolchain.sh` OK — Greenforce Cirrus 24.0.0 (VERIFIED)
- [x] Build lokal `MAKE_EXIT=0` (log `/tmp/opencode/build-batchC.log`), `grep -c 'error:' = 0`,
  `Image.gz-dtb` 12M keluar, `.config` fingerprint `CONFIG_CLANG_VERSION=240000`,
  `CONFIG_KSU=y` + `MANUAL_HOOK` + `HOSTSREDIRECT` + `NOMOUNT` semua ada (VERIFIED)
- [ ] Flash & boot-test di hardware selene (uname, config.gz, feature probe) — NOT CHECKED

## Regression test

- Setiap patch `cherry-pick -x` harus bawa `(cherry picked from commit ...)`
- Patch yang conflict → port manual per-hunk, jangan `-X theirs` wholesale
- Build gagal → revert commit itu, catat di issue ini (jangan tambal diam-diam)
