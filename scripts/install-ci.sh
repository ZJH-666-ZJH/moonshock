#!/usr/bin/env bash
# Linux x86_64; official immutable compiler/core URLs, checked downloaded hashes.
set -euo pipefail
install_root="${1:?pass an empty dedicated installation directory}"
if [[ -e "$install_root" ]]; then
  echo 'Installation destination must not exist' >&2
  exit 1
fi
mkdir -p "$install_root/lib"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
version='0.10.20%2B65efd5b93'
curl --fail --silent --show-error --location --connect-timeout 15 --max-time 180 \
  "https://cli.moonbitlang.com/binaries/$version/moonbit-linux-x86_64.tar.gz" -o "$work/compiler.tar.gz"
curl --fail --silent --show-error --location --connect-timeout 15 --max-time 90 \
  "https://cli.moonbitlang.com/cores/core-$version.zip" -o "$work/core.zip"
printf '%s  %s\n' '80d987523308fa490eba9f1baf98df996a5a7891e118357553b7c2608c0597c5' "$work/compiler.tar.gz" \
  'd7982eed233e0c4f933f566274cc9777466447e0d5b633006e8bf18975c7c833' "$work/core.zip" | sha256sum --check
tar -xzf "$work/compiler.tar.gz" -C "$install_root"
python3 - "$work/core.zip" "$install_root/lib" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    archive.extractall(sys.argv[2])
PY
export MOON_TOOLCHAIN_ROOT="$install_root"
export PATH="$install_root/bin:$PATH"
(cd "$install_root/lib/core" && moon bundle --warn-list -a --all)
moon version --all
if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$install_root/bin" >> "$GITHUB_PATH"
  printf 'MOON_TOOLCHAIN_ROOT=%s\n' "$install_root" >> "$GITHUB_ENV"
fi
