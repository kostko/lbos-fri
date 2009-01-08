.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

mov r0, #1
mov r1, #1

swi #SYS_WAIT

ldr r10, TESTBUF
str r10, MEM
ldr r10, MEM
add r10, r10, #12
str r10, ID

mov r0, #2
mov r1, #1
swi #SYS_SIGNAL

swi #SYS_EXIT


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "www"
ID: .asciz "3"
MEM: .space 20
