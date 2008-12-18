/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/G8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

/**
 * This task writes to serial console 
 */
task_sertest:
  /* prints 65534 'A's and one 'C' */
  ldr r0, =SER_PRINT_BUF
  mov r1, #65536
  sub r1, r1, #1
  swi #SYS_PRINT
  
  swi #SYS_EXIT

  b task_sertest

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

SER_PRINT_BUF: .space 65534, 'A'
               .space 3,   'C'
