  .section .init
  .globl _start
_start:
  la   sp, __stack_top
  call main
1: j 1b
  .section .bss
  .balign 16
  .global __stack_top
__stack_top:
  .space 4096
