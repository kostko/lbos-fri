.section task_code, "ax"
.code 32

.include "include/structures.s"

task2:

  ldr r3,=24000000           
  do_something:                      
     subs r3,r3,#1
  bne do_something 
  
  /* Delay 25 ms */
  mov r0, #25
  swi #SYS_DELAY 
 
  b task2

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

