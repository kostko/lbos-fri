/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"

.global printk
printk:
  /* Output stuff via the debug unit. Before calling this
     function, r0 should contain a pointer to a NULL terminated
     string. */
  stmfd sp!, {r0-r4,lr}
  ldr r3, =DBGU_BASE
  
__pk_write_loop:
  ldrb r1, [r0], #1
  cmp r1, #0
  beq __pk_end
  
  /* Wait until we can transmit something */
__pk_txwait_loop:
  ldr r2, [r3, #DBGU_SR]  /* Read DBGU Status Register */
  ands r2, r2, #2         /* Check if TXRDY bit is set */
  beq __pk_txwait_loop    /* If it is not set, wait some more */
  
  /* Transmit one character by writing to DBGU_THR */
  strb r1, [r3, #DBGU_THR]
  b __pk_write_loop
  
__pk_end:
  ldmfd sp!, {r0-r4,pc}

