/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
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

/* ==============================================================================================================*/
/* ============================== MONITOR =======================================================================*/
/* ==============================================================================================================*/
  mov r1, #0
  
  /* V R11 DOBIMO NASLOV TCBLIST ----------------------*/
  mov r10, #0
  swi #SYS_GETC
  mov r2, r11
  mov r10, r11

	ldr r1, = LINE
    
  ldr r4, = TLINK
  str r11, [r4]
  
  @ldr r2, = TCBLIST2 						        /*   R2 <-- Address of the first TCB  */

/* REGISTER USAGE
 * R1 - Line Address
 * R2 - TCB Pointer
*/

  @ CHANGING TCBSEQ
  
  ldr r3, = TCBSEQ
  mov r4, #1
  str r4, [r3]
                   
  MONITOR_LOOP:									                /* Reading TCBs and their parameters and storing them to LINE */
 
    ldr r1, = LINE
    
    /* V R11 DOBIMO T_LINK --------------------------*/
    /* trenutni naslov TCB damo v r10 */
    
    ldr r4, = TLINK
    ldr r10, [r4]
    
    /* v r11 damo 1, da bomo dobili T_LINK */
    mov r11, #1
    swi #SYS_GETC
    /* vrednost T_LINK-a damo v r3*/    
    mov r3, r11
    
    /* Saving T_LINK */
    ldr r4, = TLINK
    str r11, [r4]

    cmp r11, #0
    beq LAST_TCB
              
    @ INITIALIZING LINE
           
    mov r4, #32			/* ASCII code for ' ' */
    mov r5, #0
    init_loop_not_last:	
      	strb r4, [r1, r5]
        add r5, r5, #1
      	cmp r5, #79
      	blt init_loop_not_last
    mov r4, #0
    strb r4, [r1, r5]
        
    @ INITIALIZING LINE OVER
                               					            
    b WRITE_TO_LINE_AND_TERMINAL 		/* Print current TCB */
    
    MORE_TCB:

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

  ldr r4, = TLINK
  ldr r10, [r4]
/*------------------------------------------------------------*/  
  @ PROCESS NAME	( TEMP_NAME )
 
  ldr r5, = V_NAME
  
  mov r4, #78                 /* ASCII --> 'N' 	*/ 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    /* ASCII --> ':' 	*/
  strb r4, [r1, r5]
  add r5, r5, #1   

  /* V R11 DOBIMO T_NAME --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja*/
  
  mov r11, #2
  swi #SYS_GETC
  mov r6, r11

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

  @ PROCESS SSP	( TEMP_SSP )
    
  ldr r5, = V_SSP
    
  mov r4, #83                 @ ASCII --> 'S' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1

  /* V R11 DOBIMO T_SSP --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja*/
  mov r11, #4
  swi #SYS_GETC
  mov r6, r11

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

  @ PROCESS PRIOITY
      
  ldr r5, = V_PRIO
  mov r8, #0

  /* V R11 DOBIMO T_PRIO --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja*/
  mov r11, #6
  swi #SYS_GETC
  mov r6, r11
    
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

  @ PROCESS MSG POINTER	( ????? )		
    
  ldr r5, = V_MSG
  
  mov r4, #77                 @ ASCII --> 'M' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1
  
  /* V R11 DOBIMO T_MSG --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja */
  mov r11, #3
  swi #SYS_GETC
  mov r6, r11

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
  
  ldr r6, = TMPSTR1
  mov r4, #0
  
  msg_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #8
  blt msg_loop

/*------------------------------------------------------------*/  
  @ PROCESS NUMBER OF MSGs  ( M_COUNT )
  b nmsg_finish
  ldr r5, = V_NMSG

  mov r11, #3
  swi #SYS_GETC
  mov r6, r11
  mov r0, r10
      
  @ldr r6, [r2, #TEMP_MSG]
  mov r4, #0
  mov r8, #0
  cmp r6, #0
  beq nmsg_0
  
  nmsg_loop:       
    add r4, r4, #1
    
    mov r11, #7
    swi #SYS_GETC
    mov r6, r11
    mov r10, r11
    
    @ldr r6, [r6, #TEMPM_LINK]
    cmp r6, #0
    bgt nmsg_loop
        
  nmsg_0:      
    cmp r4, #10
    bge nmsg_10
    mov r7, #32
    strb r7, [r1, r5]
    add r5, r5, #1
    add r4, r4, #48
    strb r4, [r1, r5]
    b nmsg_finish
  
  nmsg_10:
  
    sub r4, r4, #10
    add r8, r8, #1
    cmp r4, #10
    bge nmsg_10
    
    add r8, r8, #48  
    strb r8, [r1, r5]
    add r5, r5, #1
    add r4, r4, #48
    strb r4, [r1, r5]
    add r5, r5, #1
    
  nmsg_finish:
  
  @mov r10, r0
/*------------------------------------------------------------*/  
 
  @ PROCESS RPLY POINTER ( TEMP_RPLY )

  ldr r5, = V_RPLY

  mov r4, #82                 @ ASCII --> 'R' 	 
  strb r4, [r1, r5]
  add r5, r5, #1
  mov r4, #58  						    @ ASCII --> ':' 	
  strb r4, [r1, r5]
  add r5, r5, #1

  /* V R11 DOBIMO T_RPLY --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja*/
  mov r11, #9
  swi #SYS_GETC
  mov r6, r11

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
    
  ldr r6, = TMPSTR1
  mov r4, #0

  rply_loop:
  
  ldrb r7, [r6, r4]
  strb r7, [r1, r5]
  add r5, r5, #1
  add r4, r4, #1
  cmp r4, #8
  blt rply_loop

/*------------------------------------------------------------*/
  @ PROCESS NUMBER OF RPLYs  ( ????? )		TODO
  b nrply_finish
  ldr r5, = V_NRPLY

  mov r11, #9
  swi #SYS_GETC  
  mov r6, r11
  mov r0, r10
    
  @ldr r6, [r2, #TEMP_RPLY]
  mov r4, #0
  mov r8, #0
  cmp r6, #0
  beq nrply_0
  
  nrply_loop:
    add r4, r4, #1
    
    mov r11, #8
    swi #SYS_GETC
    mov r6, r11
    mov r10, r11
    
    @ldr r6, [r6, #TEMPM_LINK]
    cmp r6, #0
    bne nrply_loop
    
  nrply_0:
  
    cmp r4, #10
    bge nrply_10
    mov r7, #32
    strb r7, [r1, r5]
    add r5, r5, #1
    add r4, r4, #48
    strb r4, [r1, r5]
    b nrply_finish
  
  nrply_10:
  
    sub r4, r4, #10
    add r8, r8, #1
    cmp r4, #10
    bge nrply_10
    
    add r8, r8, #48  
    strb r8, [r1, r5]
    add r5, r5, #1
    add r4, r4, #48
    strb r4, [r1, r5]
    add r5, r5, #1
    
  nrply_finish:
  
  @mov r10, r0

/*------------------------------------------------------------*/
  
  @ PROCESS FLAGS

  @ldr r10, [r2, #TEMP_FLAG]
  
  /* V R11 DOBIMO T_FLAG --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja*/
  mov r11, #5
  swi #SYS_GETC
  mov r12, r11
    
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
  
  /* V R11 DOBIMO T_LINK --------------------------*/
  /* v r10 imamo naslov trenutnega TCB-ja */
  mov r11, #1
  swi #SYS_GETC
  mov r6, r11

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
LINE:	        .space 80
TMPSTR1:      .space 8
TCBDA:         .asciz "TCBDA\n"
TCBNE:         .asciz "TCBNE\n"
TEST1:         .asciz "TEST1"
TEST2:          .asciz "TEST2"
ERRORM:         .asciz "ERROR!!!\n"

TASK11:       .skip TCBSIZE
TASK12:       .skip TCBSIZE
TASK13:       .skip TCBSIZE

IME1:         .ascii "Nejc"
IME2:         .ascii "Stme"

MSGA11:       .skip MCBSIZE
MSGA12:       .skip MCBSIZE

TCBLIST2:               .word 0
TCBSEQ:                 .word 1
LONG_TO_HEX_SEQ:        .word 1
TLINK:                  .space 4
