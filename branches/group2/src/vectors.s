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
  ldr pc, =start                  /* RESET and start */
  ldr pc, =debugger_undef         /* UNDEFINED INSTRUCTION*/
  ldr pc, =syscall_handler        /* SOFTWARE INTERRUPT */
  ldr pc, =vm_abort_handler       /* ABORT (PREFETCH) */
  ldr pc, =vm_abort_handler       /* ABORT (DATA) */
  ldr pc, =debugger_resvt         /* RESERVED */
  ldr pc, [pc, #-0x0F20]          /* IRQ INTERRUPT - to AIC */
  ldr pc, =debugger_fiqir         /* FIQ INTERRUPT */
