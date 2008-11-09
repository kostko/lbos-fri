/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.text
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

.global task_msgtest
task_msgtest:
  mov r0, #14
  mov r1, #15
  mov r2, #16
  mov r3, #17
  mov r4, #18
  mov r5, #19
  mov r6, #20
  mov r7, #21
  mov r8, #22
  mov r9, #23
  mov r10, #24
  mov r11, #25
  mov r12, #26
  
  /* Receive data from the other task */
  swi #SYS_RECV
  /* Got something (pointer to MCB in r0) */
  /* Just leave it there */
  nop
  nop
  nop
  nop
  nop
  swi #SYS_REPLY
  
  b task_msgtest
