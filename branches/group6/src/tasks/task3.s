.section task_code, "ax"
.code 32

.include "include/structures.s"

task3:
     
  /* Turn LED OFF */
  mov r0, #0
  swi #SYS_LED 

  b task3

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

