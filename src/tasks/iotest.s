/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task_iotest:
  /* Perform MMC write to 0x0 */
  mov r0, #0
  ldr r1, =WRITE_BUFFER
  mov r2, #1024
  swi #SYS_MMC_WRITE
  
  /* READ I/O stress test */
  mov r3, #50
  
__stress_loop:
  /* Perform MMC read from 0x0 */
  mov r0, #0
  ldr r1, =READ_BUFFER
  mov r2, #1024
  swi #SYS_MMC_READ
  
  /* TODO: Verify read */
  /* TODO: Null out memory */
  
  subs r3, r3, #1
  bne __stress_loop
  
  /* Exit this task */
  swi #SYS_EXIT

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

.align 2
WRITE_BUFFER: .asciz "Hello MMC card, you are being overwritten!"
__wr_padding: .space 1024 - (__wr_padding - WRITE_BUFFER), 0x00

READ_BUFFER: .space 1024
