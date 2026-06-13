# elfpeek

`elfpeek` is a small ELF inspection tool written in Nia.

It is a Nia practice project inspired by
[Oblivionsage/elfpeek](https://github.com/Oblivionsage/elfpeek), with a focus on
being a compact example of ELF parsing, CLI error handling, and standard-library
usage in Nia.

The source entry point is `src/main.nia`. It reads an ELF file into one heap
buffer, parses ELF32/ELF64 headers in little or big endian, and exposes a few
quick inspection commands without a REPL.

## Requirements

This project is written in [Nia](https://github.com/nialang/nia). Follow the Nia
project's installation or development instructions so the `nia` command and the
matching standard library are available together.

## Layout

- `src/main.nia` - CLI parsing, file IO, and top-level resource cleanup
- `src/elf.nia` - ELF entry validation and command dispatch
- `src/elf/types.nia` - ELF constants, shared structs, and basic value helpers
- `src/elf/header.nia` - ELF and program header parsing/printing
- `src/elf/section.nia` - section table parsing, dumps, and string extraction
- `src/elf/symbol.nia` - symbol table printing and address resolution
- `src/elf/reloc.nia` - relocation table parsing/printing
- `src/command.nia` - command mode and parsed CLI request values
- `src/util.nia` - byte-order readers and small output helpers
- `src/output.nia` - standard-library stdout/stderr helpers and fixed formatting

## Build

```sh
nia check src/main.nia
nia emit --exe src/main.nia -o build/elfpeek
```

## Test

```sh
tests/run.sh
```

The test fixtures cover small ELF32/ELF64 files in little and big endian plus a
few Linux ELF64 layout variants. They are copied from the MIT-licensed
`Oblivionsage/elfpeek` test corpus and committed directly under
`tests/fixtures/`.

## Run

```sh
./build/elfpeek <elf-file>
./build/elfpeek <elf-file> 0xaddr
./build/elfpeek <elf-file> dump <.section|@offset> [len]
./build/elfpeek <elf-file> strings [.section] [min-len]
./build/elfpeek <elf-file> relocs
```

Example:

```sh
./build/elfpeek build/elfpeek
./build/elfpeek build/elfpeek dump .text 128
./build/elfpeek build/elfpeek strings .dynstr 4
```

## Design notes

The input buffer is allocated through the Nia standard-library allocator based on
the file size and released after parsing. File IO and output use `std::fs` and
`std::io`; the project no longer declares libc bindings. Section data, symbol
names, dumps, strings, and relocations are read as slices over that buffer
instead of being copied into secondary storage.

ELF32 and ELF64 records are normalized into compact structs with `u64` offsets
and addresses. Before any table entry is read, `table_entry_offset` checks both
`index * entsize` and `base + relative`; before a file slice is borrowed,
`file_range` checks `offset + size` and converts to `usize` bounds. Malformed
tables are truncated or skipped instead of driving unchecked reads.

ELF string tables stay in the byte/C-string domain. Section names, symbol names,
CLI paths, and raw dump targets are handled as `CStr` or `&[u8]` at the boundary
where that is the native representation; the tool only formats them after a NUL
terminator has been found inside the borrowed ELF string-table slice.

Output helpers return `process::ExitCode!void`, so write and flush failures are
propagated through `.?` style error handling rather than silently ignored. CLI
parse failures report usage errors instead of defaulting invalid numeric input to
zero.

## License

MIT. See `LICENSE`.
