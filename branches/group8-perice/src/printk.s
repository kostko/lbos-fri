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
 * NOTE: Generated string shouldn't exceed 512 bytes.
 *
 * @param r0 Pointer to null terminated source string
 */
printk:
  stmfd sp!, {r0-r3,lr}
  mov r2, r0

  /* Get a new empty buffer */
  bl mm_alloc_page
  mov r1, r0
  mov r0, r2

  /* We have source string in r0, output buffer in r1,
   * and correct sp, now fire vsprintf */
  bl vsprintf

  /* We have destination in r1 and number of characters
   * in r0, proceed with DMA */
  mov r2, r1
  sub r1, r0, #1 /* strip final \0 */
  mov r0, r2
  bl serial_write_request
  
  ldmfd sp!,{r0-r3,pc}

