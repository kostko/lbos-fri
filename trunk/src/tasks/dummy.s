/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

.global task_dummy
task_dummy:

  mov r0, #1
  mov r1, #2
  mov r2, #3
  mov r3, #4
  mov r4, #5
  
  /* Delay 500 ms */
  mov r0, #500
  swi #SYS_DELAY
  
  /* Turn LED on */
  mov r0, #1
  swi #SYS_LED
  
  /* Delay 500 ms */
  mov r0, #500
  swi #SYS_DELAY
  
  /* Turn LED off */
  mov r0, #0
  swi #SYS_LED
  
  mov r5, #6
  mov r6, #7
  mov r7, #8
  mov r8, #9
  mov r9, #10
  mov r10, #11
  mov r11, #12
  mov r12, #13
  
  /* Send something to other task */
  mov r0, #TESTBUF
  mov r1, #6
  mov r2, #1
  swi #SYS_SEND
  
  b task_dummy

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "Hello"
