#!/bin/bash

set -e
script_dir="$(cd "$(dirname "$0")"; pwd -P)"

# rm -rf *.o
# riscv64-unknown-elf-gcc -g -Og -o sample.o -c sample.c
# riscv64-unknown-elf-gcc -g -Og -o start.o -c ${script_dir}/../template/start.S
# riscv64-unknown-elf-gcc -T ${script_dir}/../template/spike.lds -nostartfiles -o sample sample.o start.o

rvcc -g -Og sample.c -o sample
