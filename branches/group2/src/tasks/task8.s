.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task5:

mov r0, #0
mov r1, #0

swi #SYS_WAIT

ldr r11, =MEM 
mov r9, #0xAA
str r9, [r11]
swi #SYS_NEWTASK
mov r9, #0xBB
str r9, [r11]

swi #SYS_SIGNAL

swi #SYS_EXIT


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "ssss"
ID: .asciz "888"
MEM: .space 5
