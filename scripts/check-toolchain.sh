#!/bin/sh
# check-toolchain.sh — guard before any local build.
#
# make only takes CC=clang from PATH, so when greenforce-clang/ is missing
# (or PATH was not exported) the build silently falls back to the system
# clang — no PGO/Polly, different version banner, zero errors. This script
# fails hard (exit 1) unless `clang` resolved from PATH is this worktree's
# Greenforce toolchain.
#
# Usage (same shell you will build in):
#   export PATH="$(git rev-parse --show-toplevel)/greenforce-clang/bin:$PATH"
#   scripts/check-toolchain.sh

top="$(git rev-parse --show-toplevel 2>/dev/null)" || {
	echo "check-toolchain: not inside the kernel git tree" >&2
	exit 1
}

# make does not resolve tools with "allow_unexistent" — emulate PATH lookup.
clang="$(command -v clang 2>/dev/null)" || clang=""
fail() {
	echo "check-toolchain: FAIL — $1" >&2
	echo "  fix: export PATH=\"$top/greenforce-clang/bin:\$PATH\"" >&2
	echo "       then re-run scripts/check-toolchain.sh" >&2
	exit 1
}

case "$clang" in
"$top"/greenforce-clang/bin/* | "")
	;;
*)
	fail "PATH clang '$clang' is not this tree's greenforce-clang (unknown toolchain would win the build)"
	;;
esac
[ -n "$clang" ] || fail "no clang found in PATH"
[ -x "$top/greenforce-clang/bin/clang" ] || fail "$top/greenforce-clang/bin/clang missing — toolchain absent, re-install greenforce-clang"

ver="$("$top/greenforce-clang/bin/clang" --version 2>&1 | head -n1)"
case "$ver" in
Cirrus\ clang\ *) ;;
*) fail "unexpected clang banner '$ver'" ;;
esac

echo "check-toolchain: OK — $clang"
echo "  $ver"
if [ -r "$top/greenforce-clang/BASE_VERSION" ]; then
	sed -n 's/^release: /  release: /p' "$top/greenforce-clang/BASE_VERSION"
fi
