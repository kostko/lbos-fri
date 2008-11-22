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
     string (optionally with modifiers (see vsprintf.s) in which 
     case arguments are passed on stack). */
  stmfd sp!, {r0-r3,lr}  
  
  /* Get empty slot on buffer into r1
   * and prepare for next transfer */
  ldr r2, =PK_BUFFER_LAST
  add r3, r2, #PK_BUFFER_SIZE
  ldr r1, [r3]
  cmp r1, r2
  mov r2, r1
  addne r2, r2, #PK_BUFFER_SIZE
  subeq r2, r2, #PK_BUFFER_BACK
  str r2, [r3]
  
  /* We have source string in r0, output buffer in r1,
   * and correct sp, now fire off vsprintf */
  bl vsprintf
  
  /* We have destination in r1 and number of characters
   * in r0, proceed with DMA */
  sub r0, r0, #1 /* strip final \0 */
  ldr r3, =DBGU_BASE
__pk_wait:
  ldr r2, [r3, #PDC_TNCR]
  cmp r2, #0  /* Is there no queued transmission? */
  bne __pk_wait
  ldr r2, [r3, #PDC_TCR]
  cmp r2, #0  /* Is there no active transmission? */
  /* add r1, r1, #0x200000 */
  strne r1, [r3, #PDC_TNPR]
  strne r0, [r3, #PDC_TNCR] /* Pass number of characters to queued */
  /*moveq r2, #(1 << 9)   /* Disable DMA Transmition if not active */
  /*streq r2, [r3, #PDC_PTCR]*/
  streq r1, [r3, #PDC_TPR]
  streq r0, [r3, #PDC_TCR] /* Pass number of characters to active */
  /*moveq r2, #(1 << 8)       /* Enable DMA Transmition if wasn't active */
  /*streq r2, [r3, #PDC_PTCR]*/
  
  ldmfd sp!,{r0-r3,pc}

  
.data 

/* Circular list of three buffers */
.equ PK_BUFFER_SIZE, 512
.equ PK_BUFFER_BACK, 2*PK_BUFFER_SIZE /* Jump back to start distance */

.align 4
PK_BUFFER_START:
PK_BUFFER_1:   .space PK_BUFFER_SIZE
PK_BUFFER_2:   .space PK_BUFFER_SIZE
PK_BUFFER_LAST:
PK_BUFFER_3:   .space PK_BUFFER_SIZE
PK_BUFFER_PTR: .word PK_BUFFER_START
       
