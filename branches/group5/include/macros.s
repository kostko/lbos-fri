/* ================================================================
                             USEFUL MACROS
   ================================================================
*/
.macro DISABLE_IRQ
  mrs r12, cpsr           /* Load CPSR to r12 */
  orr r12, r12, #(3 << 6) /* Set IRQ, FIQ disable bits (7, 8) */
  msr cpsr_c, r12         /* Write r12 to CPSR */
.endm

.macro ENABLE_IRQ
  mrs r12, cpsr           /* Load CPSR to r12 */
  bic r12, r12, #(3 << 6) /* Clear IRQ, FIQ disable bits (7, 8) */
  msr cpsr_c, r12         /* Write r12 to CPSR */
.endm

.macro DISABLE_PIT_IRQ
  ldr r11, =PIT_BASE
  ldr r12, [r11, #PIT_MR]
  bic r12, r12, #(1 << 25)  /* Clear PITIEN bit */
  str r12, [r11, #PIT_MR]
.endm

.macro ENABLE_PIT_IRQ
  ldr r11, =PIT_BASE
  ldr r12, [r11, #PIT_MR]
  orr r12, r12, #(1 << 25)  /* Set PITIEN bit */
  str r12, [r11, #PIT_MR]
.endm

.macro LED_ON
  ldr r0, =PIOC_BASE
  mov r1, #(1 << 1)
  str r1, [r0, #PIO_CODR]
.endm

.macro LED_OFF
  ldr r0, =PIOC_BASE
  mov r1, #(1 << 1)
  str r1, [r0, #PIO_SODR]
.endm

.macro PUSH_CONTEXT
  str lr, [sp, #-4]!      /* Push return address to stack */
  sub sp, sp, #4          /* Adjust stack pointer (no supervisor link reg.) */
  stmfd sp!, {r14}^       /* Push user link register to stack */
  stmfd sp!, {r0-r12}     /* Push r0-r12 to stack */
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
  
  stmfd sp!, {r0}         /* Push return address to stack */
  stmfd sp!, {lr}         /* Push supervisor link register to stack */
  stmfd sp!, {lr}^        /* Push user link register to stack */
  stmfd sp!, {r4-r12}     /* Push r4-r12 to SVC stack */
  ldmfd r1!, {r9-r12}     /* Pop orig. r0-r3 previously saved */
  stmfd sp!, {r3,r9-r12}  /* Push r0-r3, SPSR to SVC stack */
.endm

.macro POP_CONTEXT
  ldmfd sp!, {r12}          /* Pop PSR from stack */
  msr spsr_all, r12         /* Save PSR in SPSR */
  ldmfd sp!, {r0-r12}       /* Restore registers r0-r12 */
  ldmfd sp!, {lr}^          /* Restore user mode link register */
  ldmfd sp!, {lr}           /* Restore supervisor mode link register */
  ldmfd sp!, {pc}^          /* Restore PC and CPSR */
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
  str r0, [sp, #SCTX_REG]    /* Modify r0 on the stack */
.endm

.macro LOAD_CURRENT_TCB reg
  ldr \reg, =CURRENT
  ldr \reg, [\reg]
.endm

.macro LOAD_ROOT_DIR reg
  ldr \reg, =D_ROOT
.endm

.macro LOAD_CURRENT_DIR reg
  ldr \reg, =CURRENT
  ldr \reg, [\reg, #T_CURDIR]
.endm

.macro STORE_CURRENT_DIR reg
	stmfd sp!, {r5}         	/* push r5 to stack */
  ldr r5, =CURRENT
	str \reg, [r5, #T_CURDIR]
	ldmfd sp!, {r5}						/* pop r5 from stack */
.endm
