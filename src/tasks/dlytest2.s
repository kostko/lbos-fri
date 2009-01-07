/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task_dlytest2:

  mov r0, #46080
  
__td2_loop:		
  subs r0, r0, #1
  bne  __td2_loop
			  
  b task_dlytest2
  
