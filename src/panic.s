/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global printk
.global panic

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"

.code 32
.text
/**
 * Enters an infinite loop.
 *
 * @param r0 Pointer to a NULL terminated string to output
 */
panic:
  DISABLE_IRQ
  stmfd sp!, {r0}
  ldr r0, =MSG_PANIC
  bl printk

__kpanic_loop:
  b __kpanic_loop

.data
MSG_PANIC: .asciz "AIEEE! KERNEL PANIC: %s"
