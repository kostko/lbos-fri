/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global sys_irq_handler
.global svc_newtask

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/macros.s"

.text
.code 32
sys_irq_handler:
  /* System controller interrupt handler */
  sub r14, r14, #4
  PUSH_CONTEXT_SVC
  
  /* Check if PIT is responsible for this interrupt (since
      SYSC IRQ channel is shared) */
  ldr r0, =PIT_BASE
  ldr r1, [r0, #PIT_SR]
  cmp r1, #1
  beq __pit_irq_handler
  
  /* Nothing matched */

  /* Signal AIC end of interrupt and return */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  
  POP_CONTEXT

__pit_irq_handler:
  /* PIT handler, just switch to next task */
  
  /* Acknowledge interrupt */
  ldr r0, =PIT_BASE
  ldr r0, [r0, #PIT_PIVR]
  
  /* Signal end of interrupt handling to AIC */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  b svc_newtask
