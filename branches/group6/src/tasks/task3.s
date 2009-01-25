.section task_code, "ax"
.code 32

.include "include/structures.s"

task3:

  /* Turn LED OFF */
  mov r0, #0
  swi #SYS_LED 
  
  ldr r3,=2400000            
  do_something:                      
     subs r3,r3,#1
  bne do_something 
  
  /* Delay 300 ms */
  mov r0, #300
  swi #SYS_DELAY 



  b task3

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

