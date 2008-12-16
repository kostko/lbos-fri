======================================================================
  LBOS-FRI DEVELOPMENT GUIDELINES - READ BEFORE COMMITTING ANY CODE !
======================================================================

1a. Physical memory layout
----------------------------------------------------------------------
Currently the memory layout is as follows:
  [4KB ] 0x00000000 - 0x00001000 BOOT MEMORY (mapped to SRAM0), CODE
  [4KB ] 0x00300000 - 0x00301000 SRAM1
  [32MB] 0x20000000 - 0x22000000 SDRAM
           0x20000000            KERNEL CODE START
           0x20080000            KERNEL DATA START
           0x20180000            KERNEL STACK END
           0x20200000            TASK AREA START

To load high-memory data structures you have to use something like:
  ldr r0, =STRUCTURE_LABEL
  ldr r1, [r0]

1b. Virtual memory layout
----------------------------------------------------------------------
LBOS-FRI now supports virtual memory and has the following layout
for each userspace task:
  
  VA         | PA         | Size | Description
  -----------+------------+------+-----------------------------------
  0x20000000 | 0x20000000 | 32M  | Kernel accessible SDRAM (id map).
  -----------+------------+------+-----------------------------------
  0x30000000 | per-task   | 256K | Per-task mapped space
  -----------+------------+------+-----------------------------------
  0xA0000000 | dynamic    | 32M  | Kernel heap space
  -----------+------------+------+-----------------------------------
  0xF0000000 | 0xF0000000 | 256M | Internal peripherals (id map).

Any address not listed in the above table is marked as invalid in the
MMU translation tables and as such will generate an abort exception.

Also note that userspace tasks are confined to their mapped space and
cannot access anything beyond it! Attempting to do so will generate a
protection fault.

WARNING #1: Since buffer pointers passed to syscalls are all in task
space, we MUST first resolve them to their respective physical
addresses (since we don't have swapping this is not a problem). If you
don't do this, buffer pointers passed to the kernel will be invalid
and will cause the kernel to crash!

WARNING #2: Message passing requires the kernel to copy the buffer to
destination task's space!

2. System call invocation
----------------------------------------------------------------------
Use the SWI instruction for invoking system calls as follows:
    SWI #0x1
or  SWI #SYS_NEWTASK

Where 0x1 is the SYSCALL NUMBER as defined in syscall.s/SYSCALL_TABLE
or mnemonic as defined in include/structures.s.
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
     0x38   | LR-usr  | SCTX_USR_LR
     0x3C   | LR-svc  | SCTX_SVC_LR
     0x40   | PC      | SCTX_PC

Where registers are as follows:
 R0-R12 - general purpuse registers
 PSR    - program status register (in SPSR after mode switch)
 PC     - task program counter
 LR-svc - Supervisor mode link register
 LR-usr - User mode link register

If you change the layout don't forget to fix *_CONTEXT macros and all
SCTX_* constants defined in include/structures.s. Also note that you
should only add new stuff at the top, above SCTX_REG, because context
switches are faster if we can load R0-PC in one instruction and switch
SPSR to CPSR at the same time.

5. Notes about adding new tasks & Virtual Memory
----------------------------------------------------------------------
Currently each task gets 256KB of memory; both for code and data. This 
is due to the current virtual memory implementation (everything is static). 
All tasks live in their own private space starting at 0x30000000 and
are currently allocated 256KB as mentioned above. Any access outside this
area will cause a protection fault (not handled ATM)!

So for each task you add you MUST:
  Modify space.s:
  - Reserve space for its TCB
  - Add the proper TCB label to the TASKTAB 
  - Add a new entry to the TASKINIT table 
  
  Modify globals.s:
  - Increment MAXTASK
  
  Modify layout.ind:
  - Add a new task section; note that each task must be aligned to a 256K
    address!

Also:	
  - Be sure to check existing tasks for reference!

6. Reference manuals
----------------------------------------------------------------------
ARMv4T Partial Instruction Set Summary
http://www.google.com/search?q=ARMv4T+Instruction+Set+Summary

GNU ARM Assembler Quick Reference
http://www.google.com/search?q=GNU+ARM+Assembler+Quick+Reference

ARM926EJ-S Technical Reference Manual
http://www.google.com/search?q=ARM926EJ-S+Technical+Reference+Manual

AT91 ARM Thumb Microcontrollers AT91SAM9260 Preliminary Summary
http://laps.fri.uni-lj.si/ars/ars_files/AT91SAM9260.pdf

ARM v5TE Architecture Reference Manual
http://www.arm.com/community/university/eulaarmarm.html
