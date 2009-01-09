.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task2:

mov r0, #0
mov r1, #1

swi #SYS_WAIT

ldr r10, TESTBUF
adr r11, MEM 
str r10, [r11]
add r11, r11, #12
ldr r9, ID
str r9, [r11]

mov r0, #1
mov r1, #1
swi #SYS_SIGNAL

swi #SYS_EXIT


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTBUF: .asciz "wwww"
ID: .asciz "111"
MEM: .space 20
