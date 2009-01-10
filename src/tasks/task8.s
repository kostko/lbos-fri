.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task8:

swi #SYS_EXIT




/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

