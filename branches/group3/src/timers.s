/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global timer_irq_handler

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
  
  /* Load destination task's TCB and clear timer flags */
  ldr   r2, =CDLYTCB                    /* r2 -> naslov na TCB, ki je trenutno v štetju */
  ldr   r1, [r2]                        /* r1 -> TCB trenutnega DLY bloka (ki je v štetju) */
  ldr   r4, [r1, #T_FLAG]               /* preberi vrstico z zastavicami iz TCB-ja */
  bic   r4, r4, #TWAIT                  /* izbrisi TWAIT zastavico */
  str   r4, [r1, #T_FLAG]               /* shrani vrstico z zastavicami v TCB */
  mov   r4, #-1
  str   r4, [r2]

  /* Read TC0 status register */
  ldr r0, =TC0_BASE
  ldr r0, [r0, #TC_SR]
  
  /* Signal end of IRQ handler */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]	
  
  ldmfd sp!, {r0-r4,pc}^
