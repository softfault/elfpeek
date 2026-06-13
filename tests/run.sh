#!/usr/bin/env sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN="$ROOT/build/elfpeek"
TMP="$ROOT/tests/tmp"

mkdir -p "$ROOT/build" "$TMP"

nia check "$ROOT/src/main.nia"
nia emit --exe "$ROOT/src/main.nia" -o "$BIN"

run_case() {
    name=$1
    shift
    out="$TMP/$name.out"
    "$BIN" "$@" > "$out"
}

assert_contains() {
    file=$1
    text=$2
    if ! grep -Fq "$text" "$file"; then
        echo "missing expected text in $file: $text" >&2
        exit 1
    fi
}

for fixture in "$ROOT"/tests/fixtures/*.bin; do
    base=$(basename "$fixture" .bin)
    run_case "$base" "$fixture"
    assert_contains "$TMP/$base.out" "ELF header"
    assert_contains "$TMP/$base.out" "Program headers"
done

assert_contains "$TMP/elf32_le.out" "Class:                 ELF32"
assert_contains "$TMP/elf32_le.out" "Data:                  little endian"
assert_contains "$TMP/elf32_be.out" "Class:                 ELF32"
assert_contains "$TMP/elf32_be.out" "Data:                  big endian"
assert_contains "$TMP/elf64_be.out" "Class:                 ELF64"
assert_contains "$TMP/elf64_be.out" "Data:                  big endian"
assert_contains "$TMP/elf64_le_segments_only.out" "Sections"
assert_contains "$TMP/elf64_le_dynsym_only.out" "Dynamic symbols"

run_case dump "$ROOT/tests/fixtures/elf64_le_pie.bin" dump @0 16
assert_contains "$TMP/dump.out" "Dump"
assert_contains "$TMP/dump.out" "7f 45 4c 46"

run_case strings "$ROOT/tests/fixtures/elf64_le_pie.bin" strings .rodata 4
assert_contains "$TMP/strings.out" "Strings from .rodata"

run_case relocs "$ROOT/tests/fixtures/elf64_le_so.bin" relocs
assert_contains "$TMP/relocs.out" "Relocations"

echo "tests passed"
