                       /*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

.global task_testmsg4
task_testmsg4:

mov r9, #0
mov r8, #0
     swi #SYS_EXIT
loop:

   cmp r8,#0
   ldreq r7,=TEXT
   ldreqb r8,[r7,r9]
   
   inner:
   ldr r0, =CRKA
   mov r1, #1      
   swi #SYS_RECV
   ldr r4,[r0, #M_BUFF]
   ldrb r5, [r4]  
   swi #SYS_REPLY
   
   cmp r8,r5
   addeq r9,r9,#1
   moveq r8,#0
   
   cmp r9,#4
   ldreq r0,=TEXT
   ldrne r0,=NULL
   
   moveq r1, #4
   movne r1,#4
   mov r2, #3
   swi #SYS_SEND
   
   beq end
   
   cmp r8,#0
   beq loop
   
   b inner

  end:
  swi #SYS_EXIT
  
  
  b task_testmsg4

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TEXT: .asciz " CAR"
NULL: .word 0x0
CRKA: .space 1
