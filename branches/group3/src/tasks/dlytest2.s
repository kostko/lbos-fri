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
			
  /* Turn LED on */
  mov r0, #1
  swi #SYS_LED
			
  /* Delay 200 ms */
  mov r0, #200
  swi #SYS_DELAY
  
  /* Turn LED off */
  mov r0, #0
  swi #SYS_LED
			  
  b task_dlytest2
  