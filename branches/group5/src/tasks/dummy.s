/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */    
.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/macros.s"


task_dummy:

  DISABLE_IRQ
  
  
  /* Create new directory */
  ldr r1, =TESTDIR
	mov r2, #0
  swi #SYS_MKDIR
	
	/* Change directory into that newly created dir */
	ldr r1, =TESTDIR
	mov r2, #0
	mov r3, #0
	mov r4, #0
	swi #SYS_CHDIR
	
	/* call dir up back to root */
	swi #SYS_DIRUP
	
	/* delete newly created directory */
	ldr r1, =TESTDIR
	swi #SYS_REMDIR
  
	mov r3, #4
  mov r4, #5
  mov r5, #6
	
	/* basic linux dir structure */
	
	/* Create new directory */
  ldr r1, =BIN
	mov r2, #0
  swi #SYS_MKDIR
	
	ldr r1, =HOME
	mov r2, #0
  swi #SYS_MKDIR
	
	ldr r1, =MEDIA
	mov r2, #0
  swi #SYS_MKDIR
	
	/* Change directory into media dir */
	ldr r1, =MEDIA
	mov r2, #0
	mov r3, #0
	mov r4, #0
	swi #SYS_CHDIR
	
	ldr r1, =CDROM
	mov r2, #0
  swi #SYS_MKDIR
	
	/* call dir up back to root */
	swi #SYS_DIRUP
	
  
  swi #SYS_EXIT

/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TESTDIR: .asciz "DirName"
BIN: .asciz "bin"
HOME: .asciz "home"
MEDIA: .asciz "media"
CDROM: .asciz "cdrom"
