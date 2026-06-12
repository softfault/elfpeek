# elfpeek

`elfpeek` is a small ELF inspection tool written in Nia.

The source entry point is `src/main.nia`. It reads an ELF file into one heap
buffer, parses ELF32/ELF64 headers in little or big endian, and exposes a few
quick inspection commands without a REPL.

## Requirements

This project is written in [Nia](https://github.com/nialang/nia). Build it with
`nia`, the Nia compiler.

If you have Rust/Cargo installed, one way to install the compiler is:

```sh
cargo install --git https://github.com/nialang/nia nia-cli
```

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
- `src/c.nia` - C ABI declarations

## Build

```sh
nia check src/main.nia
nia emit exe src/main.nia -o build/elfpeek
```

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

The input buffer is allocated with `malloc` based on the file size and released
after parsing. Section data, symbol names, dumps, strings, and relocations are
read as slices over that buffer instead of being copied into secondary storage.

## License

MIT. See `LICENSE`.
