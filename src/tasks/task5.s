.section task_code, "ax"
.code 32

.include "include/structures.s"

task5:

   swi #SYS_RECV
   swi #SYS_REPLY
  
  b task5

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
