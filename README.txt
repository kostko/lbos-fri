======================================================================
  LBOS-FRI DEVELOPMENT GUIDELINES - READ BEFORE COMMITTING ANY CODE !
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

        Macro name          | Description                | Regs 
  --------------------------+----------------------------+----------
  ENABLE_IRQ                | Enables CPU interrupts.    | r0
  --------------------------+----------------------------+----------
  DISABLE_IRQ               | Disables CPU interrupts.   | r0
  --------------------------+----------------------------+----------
  LED_ON                    | Turns the LED on.          | r0, r1
  --------------------------+----------------------------+----------
  LED_OFF                   | Turns the LED off.         | r0, r1
  --------------------------+----------------------------+----------
  SAVE_CURRENT_CONTEXT      | Saves current context to   | r12
                            | local stack.               |
  --------------------------+----------------------------+----------
  SWITCH_TO_CONTEXT         | Switches to some saved     | -
                            | context.                   |
  --------------------------+----------------------------+----------
  GET_SP <mode> <reg>       | Retrieves the sp as set in | r1, r2
                            | the specified <mode> and   | 
                            | places it into <reg>, which|
                            | MUST NOT be one of the     |
                            | used registers.            |
  --------------------------+----------------------------+----------
  SET_SP <mode> <reg>       | Sets the sp to contents of | r1, r2
                            | <reg> for <mode>. The used |
                            | <reg> MUST NOT be one of   |
                            | the used registers.        |

"Regs" values represent registers that get used by the macro and
should be expected to contain garbage after the macro has been
invoked.

4. Context structure on the stack
----------------------------------------------------------------------
Stack grows towards lower addresses. Context is pushed up as in the
following example:

  0x0FC8 PSR   <-- sp'
  0x0FCC LR
  0x0FD0 R12
    ...
  0x0FF8 R2
  0x0FFC R1
  0x1000 R0
  0x1004 .    <-- sp

Where registers are as follows:
 R0-R12 - general purpuse registers
 PSR    - program status register (in SPSR after mode switch)
 LR     - link register (contains current task PC)
