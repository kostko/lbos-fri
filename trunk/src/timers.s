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
  stmfd sp!, {r0-r4,r14}
  
  /* Read TC0 status register */
  ldr r0, =TC0_BASE
  ldr r0, [r0, #TC_SR]
  
  /* Increment current jiffies */
  ldr r0, =CUR_JIFFIES
  ldr r1, [r0]
  add r1, r1, #1
  str r1, [r0]
  
  /* Check which timers need to be fired */
  ldr r0, =TIMERQUEUE
  
__find_timers:
  ldr r2, [r0]
  cmp r2, #0
  beq __timers_done         /* If there are no more, we are done */
  
  /* Check if this timer should fire */
  ldr r3, [r2, #TM_COUNT]
  cmp r3, r1
  bls __fire_timer
  
  /* Timer should not fire, we are done, since this is an
     ordered priority queue */
  b __timers_done

__fire_timer:
  /* Remove timer from queue and put the block into free
     blocks list */
  ldr r3, [r2, #TM_LINK]
  str r3, [r0]
  
  /* Put timer back in free list */
  ldr r3, =TIMERFREE
  ldr r4, [r3]
  str r4, [r2, #TM_LINK]
  str r2, [r3]
  
  /* Load destination task's TCB and clear timer flags */
  ldr r3, [r2, #TM_TASK]
  ldr r4, [r3, #T_FLAG]
  bic r4, r4, #TWAIT
  str r4, [r3, #T_FLAG]
  
  /* Timer has fired, move on */
  b __find_timers

__timers_done:
  /* Signal end of IRQ handler */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  
  ldmfd sp!, {r0-r4,pc}^

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
  
  DISABLE_IRQ
  ldr r2, =TIMERFREE
  ldr r3, [r2]            /* Load first timer base into r3 */
  cmp r3, #0              /* Check if it is not NULL */
  beq __done
  ldr r4, [r3, #TM_LINK]  /* Get next timer in line */
  str r4, [r2]            /* Now we hold our own timer */
  ENABLE_IRQ
  
  /* Push data to timer structure */
  str r0, [r3, #TM_COUNT]
  str r1, [r3, #TM_TASK]
  
  /* Put it into the queue */
  ldr r1, =TIMERQUEUE
  
  DISABLE_IRQ
__find_queue:
  ldr r2, [r1, #TM_LINK]    /* Get link pointer */
  cmp r2, #0
  beq __place_found         /* If there are no more, we are done */
  
  /* Check if we should insert it before this one */
  ldr r4, [r2, #TM_COUNT]
  cmp r4, r0
  bhi __place_found
  
  /* Continue via links */
  mov r1, r2

__place_found:
  /* Put our timer into the queue */
  str r2, [r3, #TM_LINK]
  str r3, [r1, #TM_LINK]
  ENABLE_IRQ

__done:
  ldmfd sp!, {r0-r4,r12,pc}
