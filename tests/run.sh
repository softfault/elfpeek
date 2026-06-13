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

run_fail() {
    name=$1
    shift
    out="$TMP/$name.out"
    if "$BIN" "$@" > "$out" 2>&1; then
        echo "expected command to fail: $*" >&2
        exit 1
    fi
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
assert_contains "$TMP/elf64_le_static.out" "Type:                  EXEC (2)"
assert_contains "$TMP/elf64_le_static.out" "Machine:               x86-64 (62)"
assert_contains "$TMP/elf64_le_static.out" "Symbols"

run_case dump "$ROOT/tests/fixtures/elf64_le_pie.bin" dump @0 16
assert_contains "$TMP/dump.out" "Dump"
assert_contains "$TMP/dump.out" "7f 45 4c 46"

run_case strings "$ROOT/tests/fixtures/elf64_le_pie.bin" strings .rodata 4
assert_contains "$TMP/strings.out" "Strings from .rodata"

run_case relocs "$ROOT/tests/fixtures/elf64_le_so.bin" relocs
assert_contains "$TMP/relocs.out" "Relocations"

printf 'not an elf file fixture\n' > "$TMP/not-elf.bin"
printf '\177ELF' > "$TMP/tiny-elf.bin"

run_fail not_elf "$TMP/not-elf.bin"
assert_contains "$TMP/not_elf.out" "error: not an ELF file"

run_fail tiny_elf "$TMP/tiny-elf.bin"
assert_contains "$TMP/tiny_elf.out" "error: file is too small for an ELF ident"

run_fail invalid_dump_offset "$ROOT/tests/fixtures/elf64_le_pie.bin" dump @nope 16
assert_contains "$TMP/invalid_dump_offset.out" "error: invalid dump offset '@nope'"

run_fail missing_dump_section "$ROOT/tests/fixtures/elf64_le_pie.bin" dump .missing 16
assert_contains "$TMP/missing_dump_section.out" "error: section '.missing' not found"

run_fail invalid_dump_length "$ROOT/tests/fixtures/elf64_le_pie.bin" dump .rodata nope
assert_contains "$TMP/invalid_dump_length.out" "error: invalid dump length"

run_fail invalid_string_length "$ROOT/tests/fixtures/elf64_le_pie.bin" strings .rodata nope
assert_contains "$TMP/invalid_string_length.out" "error: invalid minimum length"

run_fail extra_relocs_arg "$ROOT/tests/fixtures/elf64_le_pie.bin" relocs extra
assert_contains "$TMP/extra_relocs_arg.out" "error: relocs does not take extra arguments"

echo "tests passed"
