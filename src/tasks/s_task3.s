.section task_code, "ax"
.code 32

.include "include/structures.s"

task3:

  mov r0, #MSG
  mov r2, #0
  swi #SYS_SEND
  
  b task3

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
MSG: .asciz "3"
