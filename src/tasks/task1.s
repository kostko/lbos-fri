.section task_code, "ax"
.code 32

.include "include/structures.s"

task1:
  
  /* Turn LED on */
  mov r0, #1
  swi #SYS_LED
  
  /* Delay 100 ms */
  mov r0, #100
  swi #SYS_DELAY     
                     
  b task1

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
