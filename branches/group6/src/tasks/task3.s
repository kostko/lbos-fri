.section task_code, "ax"
.code 32

.include "include/structures.s"

task3:


  b task3

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

