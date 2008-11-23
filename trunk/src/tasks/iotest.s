/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

.global task_iotest
task_iotest:
  /* Perform MMC read from 0x0 */
  mov r0, #0
  ldr r1, =BUFFER
  mov r2, #1024
  swi #SYS_MMC_READ
  
  /* Exit this task */
  swi #SYS_EXIT

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

.align 2
BUFFER: .space 1024

