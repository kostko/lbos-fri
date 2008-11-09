/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"

.text
.code 32

.global dispatch
dispatch:
  /* Task dispatcher */
  ldr r0, =TINDEX
  ldr r1, [r0]
  add r1, r1, #1    /* Increment task index */
  
  /* Wrap around if needed */
  cmp r1, #MAXTASK
  bne __no_wrap
  mov r1, #0

__no_wrap:
  str r1, [r0]
  mov r1, r1, lsl #2    /* Multiply r1 by 4 to get proper offset */
  ldr r2, =TASKTAB
  ldr r2, [r2, r1]      /* Load TCB address into r2 */
  ldr r3, [r2, #T_FLAG] /* Load task's flags into r3 */
  cmp r3, #0            /* Test if task is dispatchable */
  bne dispatch          /* It's not, try another one */
  
  /* Found a task to switch to (TCB in r2) */
  ldr r3, =CURRENT
  str r2, [r3]
  ldr r3, [r2, #T_USP]      /* Load task's User Stack Pointer */
  ldr r4, [r2, #T_SSP]      /* Load task's System Stack Pointer */
  
  SET_SP #PSR_MODE_SYS, r3  /* Set USP */
  mov sp, r4                /* Set SSP */
  POP_CONTEXT
