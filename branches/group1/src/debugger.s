/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

.global debugger_undef
.global debugger_abort
.global debugger_dabrt
.global debugger_resvt
.global debugger_fiqir

/* Include structure definitions and static variables */
.include "include/globals.s"
.include "include/at91sam9260.s"

.text
.code 32
  /* We are now officially screwed, output as much data
     as we can. */
.macro SWITCH_SVC_CHECK_SP_SAVE_REGS  
  /* Switch to SVC mode to see last registers */
  mov r8, #0x13
  orr r8, r8, #(3 << 6)
  msr cpsr_c, r8 

  /* Check if valid SP (sometimes 0x0, after hard reset)*/  
  cmp sp, #0x20000000
  ldrlt sp, =STACK_SUPM_END
  ldrlt sp, [sp]

  /* Save registers [R0-R15,CPSR,SPSR] */
  stmfd sp!, {r0-r15} /* this line warns, but it's OK */
  mrs r11, cpsr
  mrs r12, spsr
  stmfd sp!, {r11,r12}
.endm

debugger_undef:
  SWITCH_SVC_CHECK_SP_SAVE_REGS
  ldr r0, =DBGU_STR_UNDEF
  b debugger
debugger_abort:
  SWITCH_SVC_CHECK_SP_SAVE_REGS
  ldr r0, =DBGU_STR_ABORT
  b debugger  
debugger_dabrt:
  SWITCH_SVC_CHECK_SP_SAVE_REGS
  ldr r0, =DBGU_STR_DABRT
  b debugger
debugger_resvt:
  SWITCH_SVC_CHECK_SP_SAVE_REGS
  ldr r0, =DBGU_STR_RESVT
  b debugger
debugger_fiqir:
  SWITCH_SVC_CHECK_SP_SAVE_REGS
  ldr r0, =DBGU_STR_FIQIR
  b debugger

debugger:
  stmfd sp!,{r0} /* Push interrupt name on stack */
  /* Print debug Hello :*/
  ldr r0, =MSG_DBGU_DBGU
  bl printk
  
  /* Print xPSR registers */
  ldr r0, =MSG_DBGU_xPSR
  ldmfd sp!, {r3} /* Get CPSR from stack */ 
  mov r2, #'C'
  stmfd sp!, {r2,r3}
  bl printk
  ldmfd sp!, {r2,r3}
  ldmfd sp!, {r3} /* Get SPSR from stack */
  mov r2, #'S'
  stmfd sp!, {r2,r3}
  bl printk
  ldmfd sp!, {r2,r3}
  
  /* Print R15-R0 registers */
  mov r2, #0 /* register counter */
  ldr r0, =MSG_DBGU_REGS
__dbgu_regs_loop:
  ldmfd sp!, {r3} /* Get register from stack */
  stmfd sp!, {r2,r3}
  bl printk
  add sp, sp, #8  /* pop r2,r3 */
  add r2, r2, #1
  cmp r2, #15
  ble __dbgu_regs_loop

  /* Print last stack contents */
  ldr r0, =MSG_DBGU_STCK
  bl printk
 
  ldr r0, =MSG_DBGU_EXIT
  bl printk
     
  /* TODO */
  
__panic_loop:
  b __panic_loop

  
.data
DBGU_STR_UNDEF: .asciz "UNDEFINED INSTRUCTION"
DBGU_STR_ABORT: .asciz "ABORT (PREFETCH)"
DBGU_STR_DABRT: .asciz "ABORT (DATA)"
DBGU_STR_RESVT: .asciz "RESERVED"
DBGU_STR_FIQIR: .asciz "FIQ INTERRUPT"

MSG_DBGU_DBGU: .asciz "\n\r<<! %s\n\rEntered debugger...\n\r\n"
MSG_DBGU_REGS: .asciz " R%d:\t%x\n\r"
MSG_DBGU_xPSR: .asciz " %cPSR:\t%x\n\r"
MSG_DBGU_STCK: .asciz "\n\r On stack:\n\r\t%x\n\r\t%x\n\r\t%x\n\r\t%x\n\r\t%x ...\n\r"
MSG_DBGU_EXIT: .asciz "\n\r The Quick deBuGger Jumped oVer\n\r    iNTo teh NoT-laZy l00p.\n\r"
