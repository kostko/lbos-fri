.section task_code, "ax"
.code 32

mov r0, #2
mov r1, #1

swi SYS_WAIT

mov r10, #4


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "Hello"