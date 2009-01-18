/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group4
 */

.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"

/* ==============================================================================================================*/
/* ============================== TASK MONITOR ==================================================================*/
/* ==============================================================================================================*/

task_iotest:

  MAIN_LOOP:

/* ==============================================================================================================*
 * ============================== MONITOR =======================================================================*
 * ==============================================================================================================*/
  
  /* V R0 DOBIMO NASLOV TCBLIST-a ----------------------*/
  /*++++++++++++++++++*/
  mov r0, #0
  swi #SYS_GETC
  /*++++++++++++++++++*/

  ldr r1, = CURRTCB
  str r0, [r1]
  
	ldr r1, = LINE

  @ CHANGING TCBSEQ  
  ldr r3, = TCBSEQ
  mov r4, #1
  str r4, [r3]
  
                   
  MONITOR_LOOP:									   

    /* v r0 damo 1, da bomo dobili T_LINK */
    /*++++++++++++++++++++*/
    mov r0, #1
    swi #SYS_GETC
    /*++++++++++++++++++++*/

    ldr r4, = NEXTTCB
    str r0, [r4]
    
    /* vrednost T_LINK-a damo v r3 t.j vrednost naslednjega TCB-ja */    
    
    cmp r0, #0
    beq LAST_TCB
              
    /* INITIALIZING LINE */
           
    mov r4, #32			                        /* ASCII code for ' ' */
    mov r5, #0
    init_loop_not_last:	
      	strb r4, [r1, r5]
        add r5, r5, #1
      	cmp r5, #79
      	blt init_loop_not_last
    mov r4, #0                              /* Insertnig NULL Character*/
    strb r4, [r1, r5]
        
    /* INITIALIZING LINE OVER */
                               					            
    b WRITE_TO_LINE_AND_TERMINAL 		        /* Saving current TCB parameters to LINE */
    
    MORE_TCB:

      /* zamenjamo NEXTTCB --> CURRTCB */
      ldr r4, = NEXTTCB
      ldr r5, [r4]
      ldr r6, = CURRTCB
      str r5, [r6]
      
      ldr r0, = LINE
      swi #SYS_PRINTLN 

      b MONITOR_LOOP
    
    LAST_TCB:
               
        @ CHANGING TCBSEQ
        
        ldr r6, = TCBSEQ
        mov r4, #0
        str r4, [r6]
        
        @ INITIALIZING LINE
        
        mov r5, #32			/* ASCII code for ' ' */
        mov r6, #0
        init_loop_last:	
      	   strb r5, [r1, r6]
      	   add r6, r6, #1
      	   cmp r6, #79
      	   blt init_loop_last
        mov r5, #0
        strb r5, [r1, r6]
        
        @ INITIALIZING LINE OVER
                    
      	b WRITE_TO_LINE_AND_TERMINAL		  /* Printing the last TCB*/
        
        NO_MORE_TCB:

        ldr r0, = LINE
        swi #SYS_PRINTLN 
        
        @ INITIALIZING SEPARATOR LINE
        
        mov r5, #45			/* ASCII code for '45' */
        mov r6, #0
        init_loopSep:	
      	  strb r5, [r1, r6]
      	  add r6, r6, #1
      	  cmp r6, #78
      	  blt init_loopSep
        
        mov r7, #10					      @ ASCII --> '\n'	
        strb r7, [r1, r6]
        add r6, r6, #1
        mov r7, #0					      @ ASCII --> 'NULL'	
        strb r7, [r1, r6]
        add r6, r6, #1
                
       ldr r0, = LINE
       swi #SYS_PRINTLN 

/* ==============================================================================================================*/
/* ============================== MONITOR END====================================================================*/
/* ==============================================================================================================*/
    
  b MAIN_LOOP
  
b task_iotest

/* ==============================================================================================================*/
/* ============================== TASK MONITOR END===============================================================*/
/* ==============================================================================================================*/
  
WRITE_TO_LINE_AND_TERMINAL:	

  @ CHANGING LONG_TO_HEX_SEQ
  
  ldr r5, = LONG_TO_HEX_SEQ
  mov r6, #1
  str r6, [r5]
    
/*
REGISTER USAGE:
	- R1:	LINE Address
	- R2:	Current TCB Address
  - R3: Next TCB Address
*/

/*------------------------------------------------------------*/  
  @ PROCESS NAME	( T_NAME )
 
  ldr r5, = V_NAME
  
  mov r4, #78                 /* ASCII --> 'N' 	*/ 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    /* ASCII --> ':' 	*/
  strb r4, [r1, r5]
  add r5, r5, #1   

  /* V R0 DOBIMO T_NAME --------------------------*/
  /*++++++++++++++++++++*/

  mov r0, #2
  swi #SYS_GETC

  /*++++++++++++++++++++*/

  mov r6, r0

  and r4, r6, #127
  cmp r4, #0
  addeq r4, r4, #48
  strb r4, [r1, r5]
  add r5, r5, #1

  mov r4, r6, LSR #8
  cmp r4, #0
  addeq r4, r4, #48
  and r4, r4, #127
  strb r4, [r1, r5]
  add r5, r5, #1

  mov r4, r6, LSR #16
  cmp r4, #0
  addeq r4, r4, #48
  and r4, r4, #127
  strb r4, [r1, r5]
  add r5, r5, #1
      
  mov r4, r6, LSR #24
  cmp r4, #0
  addeq r4, r4, #48
  strb r4, [r1, r5]
  add r5, r5, #1

/*------------------------------------------------------------*/
  @ PROCESS PRIOITY
      
  ldr r5, = V_PRIO
  mov r8, #0

  /* V R0 DOBIMO T_PRIO --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #6
  swi #SYS_GETC
  /*++++++++++++++++++++*/

  mov r6, r0
    
  mov r4, #80                 @ ASCII --> 'P'
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1
  
  cmp r6, #0
  blt PRIO_end
  
  cmp r6, #10
  bge PRIO_10
  mov r7, #32
  strb r7, [r1, r5]
  add r5, r5, #1
  add r6, r6, #48
  strb r6, [r1, r5]
  add r5, r5, #1
  b PRIO_end
  
  PRIO_10:
  
  sub r6, r6, #10
  add r8, r8, #1
  cmp r6, #10
  bge PRIO_10
  add r8, r8, #48
  strb r8, [r1, r5]
  add r5, r5, #1
  add r6, r6, #48
  strb r6, [r1, r5]
  
  PRIO_end:

/*------------------------------------------------------------*/
  @ PROCESS MSG POINTER	
    
  ldr r5, = V_MSG
  
  mov r4, #77                 @ ASCII --> 'M' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1
  
  /* V R11 DOBIMO T_MSG --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #3
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  mov r6, r0

  /* MSG_LOG_TO_HEX -----------*/
  
  ldr r12, = TMPSTR1
  mov r9, #7

  lth_msg_loop:
  
  cmp r9, #0
  blt lth_msg_end  
  and r4, r6, #15
  cmp r4, #10
  addge r4, r4, #55
  addlt r4, r4, #48
  strb r4, [r12, r9]
  sub r9, r9, #1
  mov r6, r6, LSR #4
  b lth_msg_loop

  lth_msg_end:

  /* --------------------------*/
    
  ldr r6, = TMPSTR1
  mov r4, #0
  
  msg_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #8
  blt msg_loop

  ldr r5, = V_NMSG
  mov r6, #48
  add r5, r5, #1
  strb r6, [r1, r5]
    
  cmp r0, #0
  beq CONT_TO_RPLY_POINTER

/*------------------------------------------------------------*/

  @ PROCESS NMSG
  
  ldr r5, = V_NMSG

  /* V R0 DOBIMO Stevilo sporocil-------------*/
  /*++++++++++++++++++++*/
  mov r0, #7
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  and r6, r0, #3
  mov r7, #0

  nmsg_loop:
    
  cmp r6, #10
  blt nmsg_loop_over
  add r7, r7, #1
  sub r6, r6, #10

  b nmsg_loop
  
  nmsg_loop_over:
  
  cmp r7, #0
  moveq r7, #32
  addne r7, r7, #48
  strb r7, [r1, r5]
  add r5, r5, #1
  
  add r6, r6, #40
  strb r6, [r1, r5]
      
  CONT_TO_RPLY_POINTER:
  
/*------------------------------------------------------------*/
  @ PROCESS RPLY POINTER ( TEMP_RPLY )

  ldr r5, = V_RPLY

  mov r4, #82                 @ ASCII --> 'R' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1

  /* V R0 DOBIMO T_RPLY --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #9
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  mov r6, r0


  /* RPLY_LOG_TO_HEX -----------*/
  
  ldr r12, = TMPSTR1
  mov r9, #7
  
  lth_rply_loop:
  
  cmp r9, #0
  blt lth_rply_end  
  and r4, r6, #15
  cmp r4, #10
  addge r4, r4, #55
  addlt r4, r4, #48
  strb r4, [r12, r9]
  sub r9, r9, #1
  mov r6, r6, LSR #4
  b lth_rply_loop

  lth_rply_end:

  /* ----------------------------*/
      
  ldr r6, = TMPSTR1
  mov r4, #0

  rply_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #8
  blt rply_loop


  ldr r5, = V_NRPLY
  mov r6, #48
  add r5, r5, #1
  strb r6, [r1, r5]
  
  cmp r0, #0
  beq CONT_TO_SSP
  
/*------------------------------------------------------------*/

  @ PROCESS NRPLY
  
  /* V R0 DOBIMO Stevilo sporocil-------------*/
  /*++++++++++++++++++++*/
  mov r0, #8
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  and r6, r0, #3
  mov r7, #0

  nrply_loop:
    
  cmp r6, #10
  blt nrply_loop_over
  add r7, r7, #1
  sub r6, r6, #10

  b nrply_loop
  
  nrply_loop_over:
  
  cmp r7, #0
  moveq r7, #32
  addne r7, r7, #48
  strb r7, [r1, r5]
  add r5, r5, #1
  
  add r6, r6, #40
  strb r6, [r1, r5]
  
  CONT_TO_SSP:
  
/*------------------------------------------------------------*/

  @ PROCESS SSP	( T_SSP )
    
  ldr r5, = V_SSP
    
  mov r4, #83                 @ ASCII --> 'S' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1

  /* V R0 DOBIMO T_SSP --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #4
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  mov r6, r0

  /* SSP_LOG_TO_HEX -----------*/
  
  ldr r12, = TMPSTR1
  mov r9, #7
  
  lth_ssp_loop:
  
  cmp r9, #0
  blt lth_ssp_end  
  and r4, r6, #15
  cmp r4, #10
  addge r4, r4, #55
  addlt r4, r4, #48
  strb r4, [r12, r9]
  sub r9, r9, #1
  mov r6, r6, LSR #4
  b lth_ssp_loop

  lth_ssp_end:

  /* --------------------------*/
  
  ldr r6, = TMPSTR1
  mov r4, #0
  
  SSP_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #7
  ble SSP_loop

/*------------------------------------------------------------*/
  @ PROCESS FLAGS

  /* V R0 DOBIMO T_FLAG --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #5
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  mov r12, r0
    
  mov r4, #0						    @ Offset 		
  ldr r5, = V_FLAGS
 
  mov r6, #70  						  @ ASCII --> 'F' 
  strb r6, [r1, r5]
  add r5, r5, #1
  mov r6, #58  						    @ ASCII --> ':' 
  strb r6, [r1, r5]
  add r5, r5, #1

  and r6, r12, #FLAG_MASK
  
  and r7, r6, #IWAIT
  cmp r7, #1
  moveq r8, #73						    @ ASCII --> 'I'
  movne r8, #45	
  strb r8, [r1, r5]
  add r5, r5, #1
   
  and r7, r6, #MWAIT
  cmp r7, #2
  moveq r8, #77					      @ ASCII --> 'M'
  movne r8, #45	
  strb r8, [r1, r5]
  add r5, r5, #1  
  
  and r7, r6, #RWAIT
  cmp r7, #4
  moveq r8, #82					      @ ASCII --> 'R'	
  movne r8, #45
  strb r8, [r1, r5]
  add r5, r5, #1  
   
  and r7, r6, #TWAIT
  cmp r7, #8
  moveq r8, #84					      @ ASCII --> 'T'
  movne r8, #45	
  strb r8, [r1, r5]
  add r5, r5, #1  
   
  and r7, r6, #IOWAIT
  cmp r7, #16
  moveq r8, #79					      @ ASCII --> 'O'
  movne r8, #45	
  strb r8, [r1, r5]
  add r5, r5, #1  

/*------------------------------------------------------------*/
  @ PROCESS LINK
  
  ldr r5, = V_LINK
  
  mov r4, #76                 @ ASCII --> 'L' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1
  
  /* V R0 DOBIMO T_LINK --------------------------*/
  /*++++++++++++++++++++*/
  mov r0, #1
  swi #SYS_GETC
  /*++++++++++++++++++++*/
  
  mov r6, r0

  ldr r12, = TMPSTR1
  mov r9, #7
  
  lth_link_loop:
  
  cmp r9, #0
  blt lth_link_end  
  and r4, r6, #15
  cmp r4, #10
  addge r4, r4, #55
  addlt r4, r4, #48
  strb r4, [r12, r9]
  sub r9, r9, #1
  mov r6, r6, LSR #4
  b lth_link_loop

  lth_link_end:

  ldr r6, = TMPSTR1
  mov r4, #0
  
  link_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #8
  blt link_loop

/*------------------------------------------------------------*/

  mov r0, #10
  swi #SYS_GETC
  
  NEW_LINE:
  
  mov r7, #10					      @ ASCII --> '\n'	
  strb r7, [r1, r5]
  add r5, r5, #1 
  mov r7, #0					      @ ASCII --> 'NULL'	
  strb r7, [r1, r5]
  add r5, r5, #1 

  ldr r7, = TCBSEQ
  ldr r4, [r7]
  cmp r4, #1
  bge MORE_TCB
  cmp r4, #0
  beq NO_MORE_TCB
  
  ldr r0, = ERRORM
  swi #SYS_PRINTLN
                
                
/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

.align 2
CURRTCB:                .space 4
NEXTTCB:                .space 4
LINE:	                  .space 80
TMPSTR1:                .space 8
TEST1:                  .asciz "TEST1"
TEST2:                  .asciz "TEST2"
LTCB:                   .asciz "ZADNJI TCB!!!\n"
NLTCB:                  .asciz "NI ZADNJI TCB!!!!\n"
ERRORM:                 .asciz "ERROR IN WRITE_TO_LINE_AND_TERMINAL!\n"

TCBSEQ:                 .word 1
LONG_TO_HEX_SEQ:        .word 1

TLINK:                  .space 4

