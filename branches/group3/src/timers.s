/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global timer_irq_handler
.global register_timer

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"

.text
.code 32
timer_irq_handler:
  sub r14, r14, #4
  stmfd sp!, {r0-r2,r14}
  
  /* Read TC0 status register */
  ldr r0, =TC0_BASE
  ldr r0, [r0, #TC_SR]
  
  /* Increment current jiffies */
  ldr r0, =CUR_JIFFIES
  ldr r1, [r0]
  add r1, r1, #1
  str r1, [r0]
  
  /* Check if we have timers to be fired */
__find_timers:
  ldr r0, =TIMERQUEUE
  ldr r0, [r0]
  cmp r0, #0
  beq __no_more_timers
  
  /* Check if this timer should fire */
  ldr r2, [r0, #TM_COUNT]
  cmp r2, r1
  blls __fire_timer
  
  /* Timer has fired, move on */
  bls __find_timers
  
  /* no more timers in TIMERQUEUE */
__no_more_timers:
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  ldmfd sp!, {r0-r2,pc}^

  
/**
 * Fire timer.
 *
 * @param r0 Pointer to timer which need to be fired
 */
__fire_timer:
  stmfd sp!, {r0-r2,r12,lr}

  /* Remove timer from TIMERQUEUE list */
  ldr r1, =TIMERQUEUE
  ldr r2, [r0, #TM_LINK]
  str r2, [r1]
  
  /* Put timer into TIMERFREE list */
  ldr r1, =TIMERFREE
  ldr r2, [r1]
  str r2, [r0, #TM_LINK]
  str r0, [r1]
  
  /* clear timer flags */
  ldr r1, [r0, #TM_TASK]
  ldr r2, [r1, #T_FLAG]
  bic r2, r2, #TWAIT
  str r2, [r1, #T_FLAG]

  ldmfd sp!, {r0-r2,r12,pc}

  
/**
 * Registers a new timer.
 *
 * @param r0 Expiry (in number of jiffies from now)
 * @param r1 Pointer to TCB
 */
register_timer:
  stmfd sp!, {r0-r4,r12,lr}
  
  /* Calculate point in time where timer should fire */
  ldr r2, =CUR_JIFFIES
  ldr r2, [r2]
  adds r0, r0, r2
  bvs __done              /* If timer would overflow, we are done */
  
  /* Make new place for current and move TIMERFREE to next in free list*/
  ldr r2, =TIMERFREE
  ldr r3, [r2]			  /* read pointer to first in TIMERFREE */
  
  str r0, [r3, #TM_COUNT]
  str r1, [r3, #TM_TASK]  /* save current COUNT and TASK in list */
  
  DISABLE_IRQ
  ldr r1, [r3, #TM_LINK]
  str r1, [r2]			  /* move TIMERFREE to next in list */
  ENABLE_IRQ
  
  ldr r1, =TIMERQUEUE

  /* sort full list and change TIMERQUEUE if necessary */
  DISABLE_IRQ
__jump_to_next:
  ldr r2, [r1, #TM_LINK]  /* read pointer to first in TIMERQUEUE */
  cmp r2, #0
  beq __out_of_loop
  
  ldr r4, [r2, #TM_COUNT]
  cmp r4, r0			  /* compare current COUNT with COUNT in list at current position */
  movls r1, r2
  bls __jump_to_next
  
__out_of_loop:
  str r2, [r3, #TM_LINK]  /* add in list before */
  str r3, [r1, #TM_LINK]
  ENABLE_IRQ

__done:
  ldmfd sp!, {r0-r4,r12,pc}
