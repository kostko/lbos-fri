======================================================================
  LBOS-FRI DEVELOPMENT GUIDELINES - READ BEFORE COMMITING ANY CODE !
======================================================================

1. Memory layout
----------------------------------------------------------------------
Currently the memory layout is as follows:
  [4KB ] 0x00000000 - 0x00001000 BOOT MEMORY (mapped to SRAM0), CODE
  [4KB ] 0x00300000 - 0x00301000 SRAM1
  [16MB] 0x20000000 - 0x21000000 SDRAM
           0x20000000            DATA START
           0x20100000            KERNEL STACK END

To load high-memory data structures you have to use something like:
  ldr r0, =STRUCTURE_LABEL
  ldr r1, [r0]

2. System call invocation
----------------------------------------------------------------------
Use the SWI instruction for invoking system calls as follows:
  SWI #0x1

Where 0x1 is the SYSCALL NUMBER as defined in syscall.s/SYSCALL_TABLE!
System calls return values in register r0. Parameters should be passed
into r0, r1, r2, r3.

3. Macros
----------------------------------------------------------------------
The following macros are currently defined (in include/macros.s):
  ENABLE_IRQ(r0)  - Enables CPU interrupts
  DISABLE_IRQ(r0) - Disables CPU interrupts
  LED_ON(r0, r1)  - Turns the LED on
  LED_OFF(r0, r1) - Turns the LED off

Values in parenthesis represent registers that get used by the macro
and should be expected to contain garbage after the macro has been
invoked.
