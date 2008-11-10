/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

.text
.code 32

/* Global symbols */
.global start
.global syscall_handler
.global debugger

/* Vector table (must start at 0x0) */
  ldr pc, =debugger         /* RESET */
  ldr pc, =debugger         /* UNDEFINED INSTRUCTION*/
  ldr pc, =syscall_handler  /* SOFTWARE INTERRUPT */
  ldr pc, =debugger         /* ABORT (PREFETCH) */
  ldr pc, =debugger         /* ABORT (DATA) */
  ldr pc, =debugger         /* RESERVED */
  ldr pc, [pc, #-0x0F20]    /* IRQ INTERRUPT - to AIC */
  ldr pc, =debugger         /* FIQ INTERRUPT */
