.section task_code, "ax"
.code 32

.include "include/structures.s"

task4:

  mov r0, #0

  

  
  b task4

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
