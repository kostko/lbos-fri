.section task_code, "ax"
.code 32

mov r0, #0
mov r1, #1

mov r10, #1
swi SYS_SIGNAL


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "Hello"
