.section task_code, "ax"
.code 32

.include "include/structures.s"

task2:

  /* Delay 200 ms */
  mov r0, #200
  swi #SYS_DELAY
 
  b task2

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

