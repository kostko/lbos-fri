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
           0x20080000            KERNEL STACK END
           0x20100000            PAGE OFFSET

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
  ENABLE_IRQ                | Enables CPU interrupts.    | r12
  --------------------------+----------------------------+----------
  DISABLE_IRQ               | Disables CPU interrupts.   | r12
  --------------------------+----------------------------+----------
  ENABLE_PIT_IRQ            | Enable scheduler to enter  | r11, r12
                            | svc_newtask on PIT IRQ.    |
  --------------------------+----------------------------+----------
  DISABLE_PIT_IRQ           | Disable scheduler to enter | r11, r12
                            | svc_newtask on PIT IRQ.    |
  --------------------------+----------------------------+----------
  LED_ON                    | Turns the LED on.          | r0, r1
  --------------------------+----------------------------+----------
  LED_OFF                   | Turns the LED off.         | r0, r1
  --------------------------+----------------------------+----------
  PUSH_CONTEXT              | Saves current context to   | r12
                            | local stack.               |
  --------------------------+----------------------------+----------
  PUSH_CONTEXT_SVC          | Saves current context to   | r0-r3,
                            | SVC stack by first making  | r9-r12
                            | a switch to SVC mode.      |
  --------------------------+----------------------------+----------
  POP_CONTEXT               | Switches to some saved     | -
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
  --------------------------+----------------------------+----------
  SVC_RETURN_CODE <code>    | Sets r0 value on the local | r0
                            | stack to <code> (which may |
                            | be an immediate or a reg.) |
  --------------------------+----------------------------+----------
  LOAD_CURRENT_TCB <reg>    | Load current task's TCB    | -
                            | pointer into <reg>.        |

"Regs" values represent registers that get used by the macro and
should be expected to contain garbage after the macro has been
invoked.

4. Context structure on the stack
----------------------------------------------------------------------
Stack grows towards lower addresses. Context is pushed up as in the
following example:

  SP offset | Content | Offset constant
  ----------+---------+----------------
     0x00   | PSR     | SCTX_PSR
     0x04   | R0      | SCTX_REG
     0x08   | R1      |
     0x0C   | R2      |
     0x10   | R3      | 
     0x14   | R4      |
     0x18   | R5      |
     0x1C   | R6      |
     0x20   | R7      |
     0x24   | R8      |
     0x28   | R9      |
     0x2C   | R10     |
     0x30   | R11     |
     0x34   | R12     |
     0x38   | PC      | SCTX_PC

Where registers are as follows:
 R0-R12 - general purpuse registers
 PSR    - program status register (in SPSR after mode switch)
 PC     - task program counter

If you change the layout don't forget to fix *_CONTEXT macros and all
SCTX_* constants defined in include/structures.s. Also note that you
should only add new stuff at the top, above SCTX_REG, because context
switches are faster if we can load R0-PC in one instruction and switch
SPSR to CPSR at the same time.
