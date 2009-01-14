.section task_code, "ax"
.code 32

.include "include/structures.s"

task1:
  
  swi #SYS_RECV
  swi #SYS_REPLY
                     
  b task1

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"




