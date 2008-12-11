/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

/**
 * This task demonstrates how the abort handler works. 
 */
task_vmtest:

  ldr r0, =NASTY_ADDR_2   
  ldr r1, =0x12345678
  str r1, [r0]			  /* Store junk */

  /*
      This task is KILLED immediately as
	     a result of causing an abort. 
	  
	          RIP task_vmtest.
                                         */

  b task_vmtest

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

.equ NASTY_ADDR_1, 0xFFFF0000 		/* Vector table address. */
.equ NASTY_ADDR_2, 0x50000000 		/* Unmapped address. */
