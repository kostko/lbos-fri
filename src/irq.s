/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global sys_irq_handler

sys_irq_handler:
  /* System controller interrupt handler */
  b sys_irq_handler
