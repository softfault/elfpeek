# Tests

`tests/run.sh` builds `build/elfpeek` with the local `nia` command and runs a
small smoke/regression suite over ELF fixtures.

The fixture binaries in `tests/fixtures/` are copied from the MIT-licensed
`Oblivionsage/elfpeek` test corpus. They cover ELF32/ELF64, little/big endian,
PIE, shared-object, dynsym-only, and segment-only layouts. The suite checks
stable output markers rather than full golden output so formatting can evolve
without rewriting large snapshots.
