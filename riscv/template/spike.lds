OUTPUT_ARCH("riscv")
ENTRY(_start)
SECTIONS
{
  . = 0x10110000;
  .text : { *(.text) }
  .data : { 
    *(.sdata)
    *(.data)
    _bss_start = .;
    *(.bss)
    *(.sbss)
    _bss_end = .;
  }
  __stacktop = 0x10110000 + 0x20000;
}
