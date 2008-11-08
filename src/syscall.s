/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global syscall_handler
.global svc_newtask
.global dispatch

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
  
  /* Get syscall number from SWI instruction */
  ldr r0, [r14, #-4]      /* Load SWI instruction opcode + arg to r0 */
  bic r0, r0, #0xFF000000 /* Clear upper 8 bits */
  
  /* Check if SVC number is valid */
  cmp r0, #MAX_SVC_NUMBER
  bhs __bad_svc
  
  /* Get SVC address and jump to it */
  ldr r1, =SYSCALL_TABLE
  ldr r1, [r0, r1, lsl #2]
  bx r1
  
__bad_svc:
  /* Return E_BADSVC error code in r0 */
  mov r0, #E_BADSVC
  str r0, [r13]
  POP_CONTEXT

/* ================================================================
                       SYSTEM CALLS GO HERE
   ================================================================
*/

/* New task syscall */
svc_newtask:
  /* Load current task TCB pointer */
  ldr r0, =CURRENT
  ldr r0, [r0]
  cmp r0, #0
  beq dispatch      /* No current process, enter dispatch */
  
  /* Save current taks's context. */
  GET_SP #PSR_MODE_USER, r3   /* Get USP */
  str r3, [r0, #T_USP]        /* Store USP */
  str sp, [r0, #T_SSP]        /* Store SSP */

  b dispatch

/* ================================================================
                           SYCALL TABLE
   ================================================================
*/
.data
SYSCALL_TABLE:
.long svc_newtask   /* (0) enter dispatcher */

END_SYSCALL_TABLE:
.equ MAX_SVC_NUMBER, (END_SYSCALL_TABLE-SYSCALL_TABLE)/4
