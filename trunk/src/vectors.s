/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

.text
.code 32

/* Global symbols */
.global start
.global syscall_handler

/* Vector table (must start at 0x0) */
  ldr pc, =start            /* RESET */
  ldr pc, =start            /* UNDEFINED INSTRUCTION*/
  ldr pc, =syscall_handler  /* SOFTWARE INTERRUPT */
  ldr pc, =start            /* ABORT (PREFETCH) */
  ldr pc, =start            /* ABORT (DATA) */
  ldr pc, =start            /* RESERVED */
  ldr pc, [pc, #-0x0F20]    /* IRQ INTERRUPT - to AIC */
  ldr pc, =start            /* FIQ INTERRUPT */
