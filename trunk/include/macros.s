/* ================================================================
                             USEFUL MACROS
   ================================================================
*/
.macro ENABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  orr r0, r0, #1 << 7   /* Set IRQ disable bit (7) */
  msr cpsr_c, r0        /* Write r0 to CPSR */
.endm

.macro DISABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  bic r0, r0, #1 << 7   /* Clear IRQ disable bit (7) */
  msr cpsr_c, r0        /* Write r0 to CPSR */
.endm

.macro LED_ON
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  strne r1, [r0, #PIO_CODR]
.endm

.macro LED_OFF
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  strne r1, [r0, #PIO_SODR]
.endm

.macro PUSH_CONTEXT
  stmfd sp!, {r0-r12,lr}  /* Push r0-r12,lr to stack */
  mrs r12, spsr           /* Get current SPSR */
  stmfd sp!, {r12}        /* Push SPSR to stack */
.endm

.macro PUSH_CONTEXT_SVC
  /* Save registers needed for transfer to local stack */
  stmfd sp!, {r0-r3}
  mov r0, lr
  mov r1, sp
  mrs r3, spsr
  add sp, sp, #(4 << 2)
  
  /* Switch to SVC mode */
  mrs r2, cpsr
  bic r2, r2, #PSR_MODE_MASK
  orr r2, r2, #PSR_MODE_SVC
  msr cpsr_c, r2
  
  stmfd sp!, {r0}         /* Push LR to SVC stack*/
  stmfd sp!, {r4-r12}     /* Push r4-r12 to SVC stack */
  ldmfd r1!, {r9-r12}     /* Pop orig. r0-r3 previously saved */
  stmfd sp!, {r3,r9-r12}  /* Push r0-r3, SPSR to SVC stack */
.endm

.macro POP_CONTEXT
  ldmfd sp!, {r12}         /* Pop PSR from stack */
  msr spsr_all, r12        /* Save PSR in SPSR */
  ldmfd sp!, {r0-r12,pc}^  /* Restore registers, PC and CPSR */
.endm

.macro GET_SP mode reg
  /* Switch to specified mode */
  mrs r2, cpsr_all
  bic r1, r2, #PSR_MODE_MASK
  orr r1, r1, \mode
  msr cpsr_all, r1
  
  /* Get the stack pointer and restore the mode */
  mov \reg, sp
  msr cpsr_all, r2
.endm

.macro SET_SP mode, reg
  /* Switch to specified mode */
  mrs r2, cpsr_all
  bic r1, r2, #PSR_MODE_MASK
  orr r1, r1, \mode
  msr cpsr_all, r1
  
  /* Set stack pointer and restore the mode */
  mov sp, \reg
  msr cpsr_all, r2
.endm

.macro SVC_RETURN_CODE code
  mov r0, \code
  str r0, [sp, #4]    /* Modify r0 on the stack */
.endm
