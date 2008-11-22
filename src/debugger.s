/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global debugger

/* Include structure definitions and static variables */
.include "include/macros.s"
.include "include/globals.s"

.text
.code 32
debugger:
  /* We are now officially screwed, output as much data
     as we can. */
  
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
MSG_DBGU_DBGU: .asciz "\n\rEntered debugger...\n\r Register contents:\n\r"
MSG_DBGU_REGS: .asciz "  R%d:\t%x\n\r"
MSG_DBGU_xPSR: .asciz "  %cPSR:%x\n\r"
MSG_DBGU_STCK: .asciz "\n\r  On stack:\n\r\t%x\n\r\t%x\n\r\t%x\n\r\t%x\n\r  __...%x__\n\r"
MSG_DBGU_EXIT: .asciz "\n\rThe Quick deBuGger Jumped oVer iNTo teh NoT-laZy l00p.\n\r"
