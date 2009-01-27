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

.global vm_switch_ttb
.global dispatch
.global wrr_dispatch
.global prio_dispatch

/**
 * Dispatch
 */
dispatch:
  DISABLE_IRQ
    
  mov r1, #SCHEDULER  /* Load scheduling discipline */
  cmp r1, #0
  bne prio_dispatch   /* If priority scheduler, enter priority dispatch */

  /* Load number of quanta left */
  ldr r2, =Q_LEFT
  ldr r1, [r2]

  cmp r1, #0
  beq wrr_dispatch   /* If current task has no quanta left, enter wrr_dispatch */
 
  sub r1, r1, #1     /* decrement quanta left */
  str r1, [r2]       /* store new Q_LEFT */

  POP_CONTEXT

/**
 * Weighted round robin dispatch
 */
wrr_dispatch:
  mov r5, #0            /* Counter for discovering whether there are any dispatchable tasks */

  /* Load current task TCB pointer */
  ldr r4, =CURRENT
  ldr r0, [r4]

  cmp r0, #0
  beq __continue_wrr    /* If no current task, skip saving stack pointers */

  GET_SP #PSR_MODE_SYS r3    /* Get User Stack Pointer (USP) */
  str r3, [r0, #T_USP]       /* Store USP */
  str sp, [r0, #T_SSP]       /* Store System Stack Pointer (SSP) */

  /* Set no current task */
  mov r0, #0
  str r0, [r4]

__continue_wrr:
 
  cmp r5, #MAXTASK    
  beq __no_dis_task

  /* Load task index */
  ldr r0, =TINDEX
  ldr r1, [r0]

  add r1, r1, #1     /* Increment task index */

  /* Wrap around if needed */
  cmp r1, #MAXTASK
  bne __no_wrap
  mov r1, #0

__no_wrap:
  str r1, [r0]           /* Store new task index */
  mov r1, r1, lsl #2     /* Multiply r1 by 4 to get proper offset */
  ldr r2, =TASKTAB
  ldr r2, [r2, r1]       /* Load TCB address into r2 */
  ldr r3, [r2, #T_FLAG]  /* Load task's flags into r3 */
  cmp r3, #0             /* Test if task is dispatchable */
  add r5, r5, #1         /* Increment counter */
  bne __continue_wrr     /* If not, try another one */

  /* Found a task to switch to (TCB in r2) */ 
  str r2, [r4]              /* Set task as current (CURRENT's address in r4) */
  ldr r3, [r2, #T_PRIO]     /* Load "or something" (That something is a number
                               of quanta this task will be executing before
                               next one is dispatched. One quantum is the time
                               from one timer-generated interrupt to the next) */
                               
 

  /* Load quanta left */
  ldr r0, =Q_LEFT
  ldr r4, [r0]

  add r4, r4, r3            /* Add task's quanta and a possible remaining quantum */
  sub r4, r4, #1            /* Decrement Q_LEFT, first quantum has already started */
  str r4, [r0]              /* Store Q_LEFT */

  ldr r3, [r2, #T_USP]      /* Load task's USP */
  ldr r4, [r2, #T_SSP]      /* Load task's SSP */
  ldr r5, [r2, #T_TTB]      /* Load task's Translation Table Base */

  SET_SP #PSR_MODE_SYS, r3  /* Set task's USP */
  mov sp, r4                /* Set task's SSP */

  /* Switch the task's TTB */
  mov r0, r5
  bl vm_switch_ttb


  POP_CONTEXT

/**
 * Priority dispatch
 */
prio_dispatch:
  /* Load first TCB pointer from TCB list */
  ldr r5, =TCBLIST
  ldr r5, [r5]

  /* Load current task TCB pointer */
  ldr r4, =CURRENT
  ldr r0, [r4]  


  cmp r0, #0
  beq __continue_prio    /* If no current task, skip saving stack pointers */

  GET_SP #PSR_MODE_SYS r3    /* Get USP */
  str r3, [r0, #T_USP]       /* Store USP */
  str sp, [r0, #T_SSP]       /* Store SSP */

  /* Set no current task */
  mov r0, #0
  str r0, [r4]
  
  mov r8, #0

__continue_prio:
  cmp r5, #0
  beq __no_dis_task      /* If end of TCB list, enter no dispatchable task */

  ldr r3, [r5, #T_FLAG]  /* Load task's flags into r3 */
  cmp r3, #0             /* Test if task is dispatchable */
  beq __end_prio         /* If dispatchable, restore context*/
  ldr r5, [r5, #T_LINK]  /* Else, try another one */
  add r8, r8, #1
  b __continue_prio
 
__end_prio:
  /* Found a task to switch to (TCB in r5) */ 
  
  str r5, [r4]              /* Set task as current (CURRENT's address in r4) */
  ldr r3, [r5, #T_USP]      /* Load task's USP */
  ldr r4, [r5, #T_SSP]      /* Load task's SSP */
  ldr r6, [r5, #T_TTB]      /* Load task's Translation Table Base */

  SET_SP #PSR_MODE_SYS, r3  /* Set task's USP */
  mov sp, r4                /* Set task's SSP */


  /* Switch the task's TTB */
  mov r0, r6
  bl vm_switch_ttb


  POP_CONTEXT

/**
 * No dispatchable task
 */
__no_dis_task:
  ENABLE_IRQ

__forever_d:
  b __forever_d
  
