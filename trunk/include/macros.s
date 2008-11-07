/* ================================================================
                             USEFUL MACROS
   ================================================================
*/
.macro ENABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  orr r0, r0, #1 << 7   /* Set IRQ disable bit (7) */
  msr cpsr, r0          /* Write r0 to CPSR */
.endm

.macro DISABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  bic r0, r0, #1 << 7   /* Clear IRQ disable bit (7) */
  msr cpsr, r0          /* Write r0 to CPSR */
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

.macro SAVE_CURRENT_CONTEXT
  stmfd sp!, {r0-r12,lr}  /* Push r0-r12,lr to stack */
  mrs r12, spsr           /* Get current SPSR */
  stmfd sp!, {r12}        /* Push SPSR to stack */
.endm

.macro SWITCH_TO_CONTEXT a
  ldmfd \a, {r12}         /* Pop PSR from stack */
  msr spsr_all, r12       /* Save PSR in SPSR */
  ldmfd \a, {r0-r12,pc}^  /* Restore registers, PC and CPSR */
.endm

.macro GET_SP mode
  /* Switch to specified mode */
  mrs r2, cpsr_all
  bic r1, r2, #PSR_MODE_MASK
  orr r1, r1, #\mode
  msr cpsr_all, r1
  
  /* Get the stack pointer and restore the mode */
  mov r0, sp
  msr cpsr_all, r2
.endm
