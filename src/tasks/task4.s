.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task4:

mov r0, #2
mov r1, #1

swi #SYS_WAIT

ldr r11, =MEM 
mov r9, #0xAA
str r9, [r11]

swi #SYS_EXIT


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "ssss"
ID: .asciz "444"
MEM: .space 5
