                       /*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

           swi #SYS_EXIT
task_testmsg1:

 mov r4, #30
 mov r5, #0
 mov r6, #0
 mov r7, #0
 
 loop:
 cmp r4, #91    /* Check if we have reached the end of ACSII table */
 moveq r4, #30  /* Reset ascii counter*/
 ldr r11, =CHAR
 strb r4, [r11]
 
 /* P1 */
 mov r8,#4
 cmp r5,#0
 bleq podpr
 cmp r5,#0
 moveq r5,r8
 
 /* P2 */
 mov r8,#5
 cmp r6,#0
 bleq podpr
 cmp r6,#0
 moveq r6,r8  

 /* P3 */
 mov r8,#6
 cmp r7,#0
 bleq podpr
 cmp r7,#0
 moveq r7,r8

  add r4,r4,#1
  
  cmp r5,#0
  cmpne r6,#0
  cmpne r7,#0 
  beq loop
 
  /* Kopiranje */
  
  /*p1*/
  ldr r11,=TEXT
  mov r12, r5
  bl kopiraj
  /*mov r8, #32
  strb r8, [r11]
  add r11, r11, #1     */
   /*p2*/
  
  mov r12, r6
  bl kopiraj
 /* mov r8, #32
  strb r8, [r11]
  add r11, r11, #1 */
    /*p3*/
    
  mov r12, r7
  bl kopiraj
 mov r8, #33
  strb r8, [r11]
  add r11, r11, #1
  mov r8, #0
  strb r8,[r11]
  add r11, r11, #1
  
    
  swi #SYS_EXIT
b task_testmsg1
  
  podpr:
  ldr r0, =CHAR
  /* ldrb r10,[r0]*/
  mov r1, #1
  mov r2, r8
  swi #SYS_SEND

  ldr r0, =BESEDA
  mov r1, #32     
  swi #SYS_RECV
  ldr r9,[r0, #M_BUFF]
  ldr r8,[r9]
  cmp r8,#0
  movne r8, r9
  swi #SYS_REPLY
  bx lr
  
  kopiraj:
  ldrb r8,[r12]
  cmp r8,#0
  strneb r8,[r11]
  addne r11,r11,#1
  add r12, r12, #1
  bne kopiraj
  bx lr
 

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */
 
.align 4      
CHAR: .byte 90
SP:   .space 31
TEXT: .space 16  
BESEDA: .asciz "12345678901234567890123456789012"   
