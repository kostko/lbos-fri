.section task_code, "ax"
.code 32

.include "include/structures.s"

task4:

  mov r0, #MSG 
  mov r2, #4  
  swi #SYS_SEND   

  b task4


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"

MSG: .asciz "Hello"

