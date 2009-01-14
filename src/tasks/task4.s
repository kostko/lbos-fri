.section task_code, "ax"
.code 32

.include "include/structures.s"

task4:

  /* Turn LED OFF */
  mov r0, #0
  swi #SYS_LED 
  
  /* Delay 200 ms */
  mov r0, #200
  swi #SYS_DELAY
  
  b task4

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

