/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global syscall_handler
.global svc_newtask

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/macros.s"

.text
.code 32
syscall_handler:
  /* System call handler/dispatcher */
  SAVE_CURRENT_CONTEXT
  
  /* Get interrupt number from SWI instruction */
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
  SWITCH_TO_CONTEXT sp

/* ================================================================
                       SYSTEM CALLS GO HERE
   ================================================================
*/
svc_newtask:
  /* New task syscall */
  b svc_newtask

/* ================================================================
                           SYCALL TABLE
   ================================================================
*/
.data
SYSCALL_TABLE:
.long svc_newtask   /* (0) enter dispatcher */

END_SYSCALL_TABLE:
.equ MAX_SVC_NUMBER, (END_SYSCALL_TABLE-SYSCALL_TABLE)/4
