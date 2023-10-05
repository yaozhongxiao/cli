.section .text
.globl _start
.type _start, @function

_start:
    /* set stack pointer */
    /* sp = __stack_top */
    la      t0, .L_stack_top
    ld      t0, 0(t0)
    addi    sp, t0, 0

    /* call main to enter program */
    call    main
    ret

    .globl main
    .type main, @function
    .weak main
main:
    ret

.section .data
.L_stack_top:
    .dword __stacktop

.end
