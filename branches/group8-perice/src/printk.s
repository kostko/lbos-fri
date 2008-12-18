/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/G8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.global printk

/* Output kernel stuff via the debug unit. Before calling this
 * function, r0 should contain a pointer to a NULL terminated
 * string (optionally with modifiers (see vsprintf.s) in which 
 * case arguments are passed on stack).
 *
 * @param r0 Pointer to null terminated source string
 */
printk:
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
  mov r2, r1
  sub r1, r0, #1 /* strip final \0 */
  mov r0, r2
  bl serial_write_bytes
  
  ldmfd sp!,{r0-r3,pc}

  
.data 
.align /* word aligns */
/* Circular list of three buffers */
.equ PK_BUFFER_SIZE, 512
.equ PK_BUFFER_BACK, 2*PK_BUFFER_SIZE /* Jump back to start distance */
PK_BUFFER_START:
PK_BUFFER_1:   .space PK_BUFFER_SIZE
PK_BUFFER_2:   .space PK_BUFFER_SIZE
PK_BUFFER_LAST:
PK_BUFFER_3:   .space PK_BUFFER_SIZE
PK_BUFFER_PTR: .word PK_BUFFER_START
  
  
  
