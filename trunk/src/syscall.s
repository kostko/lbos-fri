/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global syscall_handler
.global svc_newtask
.global dispatch
.global register_timer

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/macros.s"
.include "include/at91sam9260.s"
.include "include/globals.s"

.text
.code 32
syscall_handler:
  /* System call handler/dispatcher */
  PUSH_CONTEXT
  ENABLE_IRQ
  
  /* Get syscall number from SWI instruction */
  ldr r12, [r14, #-4]       /* Load SWI instruction opcode + arg to r0 */
  bic r12, r12, #0xFF000000 /* Clear upper 8 bits */
  
  /* Check if SVC number is valid */
  cmp r12, #MAX_SVC_NUMBER
  bhs __bad_svc
  
  /* Get SVC address and jump to it */
  ldr r11, =SYSCALL_TABLE
  ldr r11, [r11, r12, lsl #2]
  bx r11
  
__bad_svc:
  /* Return E_BADSVC error code in r0 */
  SVC_RETURN_CODE #E_BADSVC
  POP_CONTEXT

/* ================================================================
                       SYSTEM CALLS GO HERE
   ================================================================
*/

/**
 * New task syscall.
 */
svc_newtask:
  /* Load current task TCB pointer */
  LOAD_CURRENT_TCB r0
  cmp r0, #0
  beq dispatch      /* No current process, enter dispatch */
  
  /* Save current task's context. */
  DISABLE_PIT_IRQ
  GET_SP #PSR_MODE_SYS, r3    /* Get USP */
  str r3, [r0, #T_USP]        /* Store USP */
  str sp, [r0, #T_SSP]        /* Store SSP */
  
  /* Branch to scheduler */
  b dispatch

/**
 * Print line syscall.
 */
svc_println:
  /* TODO */
  b svc_println

/**
 * Delay syscall.
 *
 * @param r0 Number of jiffies to delay execution for
 */
svc_delay:
  /* Load current task TCB pointer */
  LOAD_CURRENT_TCB r1
  
  /* Mark current task undispatchable */
  DISABLE_IRQ
  ldr r2, [r1, #T_FLAG]
  orr r2, r2, #TWAIT
  str r2, [r1, #T_FLAG]
  ENABLE_IRQ
  
  /* Register a new timer */
  bl register_timer
  
  /* Switch to some other task */
  SVC_RETURN_CODE #0
  b svc_newtask

/**
 * Send message syscall.
 *
 * @param r0 Buffer address
 * @param r1 Buffer size
 * @param r2 Task number
 */
svc_send:
  /* Check if task number is valid before grabbing any MCBs,
     otherwise we would have to return them back after an
     error is detected. */
  cmp r2, #MAXTASK
  bhs __err_badtask
  
  DISABLE_IRQ
  ldr r3, =MCBLIST
  ldr r4, [r3]          /* Load first MCB base into r3 */
  cmp r4, #0            /* Check if it is not NULL */
  beq __err_nomcbs
  ldr r5, [r4, #M_LINK] /* Get next MCB in line */
  str r5, [r3]          /* Now we hold our own MCB */
  ENABLE_IRQ
  
  /* Transfer data to MCB */
  mov r3, #0
  str r3, [r4, #M_LINK]   /* Clear M_LINK of our MCB */
  str r0, [r4, #M_BUFF]   /* Put buffer address into MCB */
  str r1, [r4, #M_COUNT]  /* Put buffer length into MCB */
  
  LOAD_CURRENT_TCB r0     /* Get pointer to current task's TCB */
  str r0, [r4, #M_RTCB]   /* Save task TCB into MCB */
  
  /* Alter task flags so it gets eliminated from dispatch
     process */
  DISABLE_IRQ
  ldr r1, [r0, #T_FLAG]
  orr r1, r1, #MWAIT
  str r1, [r0, #T_FLAG]
  ENABLE_IRQ
  
  /* Grab destination task */
  ldr r1, =TASKTAB
  ldr r1, [r1, r2, lsl #2]  /* Load destination task's TCB address */
  add r3, r1, #T_MSG        /* Calculate destination message queue address */
  
  /* Find end of queue to insert our MCB */
  DISABLE_IRQ
__find_mcb:
  ldr r0, [r3, #M_LINK]   /* Load link to next into r0 */
  cmp r0, #0
  beq __found_mcb         /* If NULL is found, we are done */
  mov r3, r0              /* Follow the M_LINK */

__found_mcb:
  str r4, [r3, #M_LINK]   /* Append our MCB to end of queue */
  
  /* Clear target task RWAIT flag */
  ldr r0, [r1, #T_FLAG]
  bic r0, r0, #RWAIT
  str r0, [r1, #T_FLAG]
  ENABLE_IRQ
  
  /* Switch to some other task */
  b svc_newtask
  
__err_nomcbs:
  /* Return E_NOMCB error code in r0 */
  SVC_RETURN_CODE #E_NOMCB
  POP_CONTEXT
  
__err_badtask:
  /* Return E_BADTASK error code in r0 */
  SVC_RETURN_CODE #E_BADTASK
  POP_CONTEXT

/**
 * Receive message syscall.
 */
svc_recv:
  /* Get current task's TCB */
  LOAD_CURRENT_TCB r0
  
  DISABLE_IRQ
  ldr r1, [r0, #T_MSG]
  cmp r1, #0            /* Check if there are any messages */
  beq __wait_for_msg    /* If none, wait */
  
  ldr r2, [r1, #M_LINK] /* Load first message link */
  str r2, [r0, #T_MSG]  /* Remove first message from queue */
  ldr r2, [r0, #T_RPLY] /* Load address of first MCB in reply queue */
  str r2, [r1, #M_LINK]
  str r1, [r0, #T_RPLY] /* Insert message into reply queue */
  
  /* Return TCB address to userspace */
  SVC_RETURN_CODE r1
  POP_CONTEXT

__wait_for_msg:
  /* Set RWAIT flag for current task */
  ldr r1, [r0, #T_FLAG]
  orr r1, r1, #RWAIT
  str r1, [r0, #T_FLAG]
  
  /* Switch to other task and retry receive */
  swi #SYS_NEWTASK
  b svc_recv

/**
 * Reply to a message syscall.
 *
 * @param r0 MCB address
 */
svc_reply:
  /* Get current task's TCB */
  LOAD_CURRENT_TCB r1
  
  /* Get list header and start MCB search to find the MCB
     directly before us */
  add r2, r1, #T_RPLY
  
  DISABLE_IRQ
__find_mcb_reply:
  ldr r3, [r2, #M_LINK]
  cmp r3, #0              /* Check if we have reached the end */
  beq __err_badmcb        /* If so, passed MCB is invalid */
  cmp r3, r0              /* Is next our MCB ? */
  beq __found_mcb_reply   /* If so, we are done */
  mov r2, r3              /* Follow the link */
  b __find_mcb_reply

__found_mcb_reply:
  /* MCB is valid, take it out (r2 = MCB before us in the list) */
  ldr r3, [r0, #M_LINK]
  str r3, [r2, #M_LINK]
  
  /* Update sender's TCB */
  ldr r3, [r0, #M_RTCB]   /* Load sender's TCB pointer to r3 */
  ldr r4, [r3, #T_SSP]    /* Load sender's stack pointer to r4 */
  ldr r5, [r0, #M_STAT]   /* Load status code */
  str r5, [r4, #4]        /* Put status code to sender's r0 on stack */
  ldr r5, [r3, #T_FLAG]   /* Load sender's flags to r5 */
  bic r5, r5, #MWAIT      /* Clear MWAIT flag */
  str r5, [r3, #T_FLAG]   /* Store flags back */
  
  /* Put MCB back in free list */
  ldr r1, =MCBLIST
  ldr r2, [r1]
  str r2, [r0, #M_LINK]
  str r0, [r1]
  
  ENABLE_IRQ
  b svc_newtask   /* Switch to some other task */

__err_badmcb:
  /* Return E_BADMCB error code in r0 */
  SVC_RETURN_CODE #E_BADMCB
  POP_CONTEXT

/**
 * LED status switch syscall.
 *
 * @param r0 LED status (0 - off, 1 - on)
 */
svc_led:
  cmp r0, #0
  beq __led_off
  LED_ON
  b __led_done
  
__led_off:
  LED_OFF
  
__led_done:
  SVC_RETURN_CODE #0
  POP_CONTEXT

/* ================================================================
                           SYCALL TABLE
   ================================================================
*/
.data
SYSCALL_TABLE:
.long svc_newtask   /* (0) enter dispatcher */
.long svc_println   /* (1) print line to serial console */
.long svc_delay     /* (2) delay */
.long svc_send      /* (3) send message */
.long svc_recv      /* (4) receive message */
.long svc_reply     /* (5) reply to a message */
.long svc_led       /* (6) LED manipulation syscall */

END_SYSCALL_TABLE:
.equ MAX_SVC_NUMBER, (END_SYSCALL_TABLE-SYSCALL_TABLE)/4