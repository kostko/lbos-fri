/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/space.s"
.include "include/macros.s"

.text
.code 32

.global start
.global sys_irq_handler
start:
  /* Switch to IRQ mode to setup the stack */
  mrs r0, cpsr         /* Load CPSR to r0 */
  bic r0, r0, #0x1F    /* Clear mode flags */
  orr r0, r0, #0xD2    /* Set IRQ mode, DISABLE IRQ/FIQ */
  msr cpsr, r0         /* Write r0 to CPSR */
  
  /* Setup the stack pointer */
  ldr r0, =STACK_IRQM_END
  ldr sp, [r0]
  
  /* Switch to supervisor mode to setup the stack and perform init */
  mrs r0, cpsr        /* Load CPSR to r0 */
  orr r0, r0, #0xD3   /* Set supervisor mode, DISABLE IRQ/FIQ */
  msr cpsr, r0        /* Write r0 to CPSR */
  
  /* Setup the stack pointer */
  ldr r0, =STACK_SUPM_END
  ldr sp, [r0]
  
  /* Setup system clocks */
  .include "include/clock_init.s"
  
  /* Enable instruction and data caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 << 12)      /* Instruction cache bit */
  orr r0, r0, #(0x1 << 2)       /* Data cache bit */
  mcr p15, 0, r0, c1, c0, 0
  
  /* Initialize system controller interrupt handler by programming AIC */
init_sysc_irq:
  /* Setup priorities for SYSC (device 1) */
  ldr r0, =AIC_BASE
  mov r1, #4
  str r1, [r0, #AIC_SMR1]
  
  /* Setup handler address for SYSC */
  ldr r1, =sys_irq_handler
  str r1, [r0, #AIC_SVR1]
  
  /* Enable interrupts for SYSC */
  mov r1, #1 << 1
  str r1, [r0, #AIC_IECR]
  
  /* Initialize the Periodic Interval Timer (PIT) that will be used by
     the task scheduler. This timer will generate "System Controller
     Interrupt" (peripheral = 1) type interrupt which is shared with
     some other devices (such as the debug unit)! */
init_pit:
  ldr r0, =PIT_BASE
  ldr r1, =PIT_MODE     /* PITEN = 1, PITIEN = 1, PIV = FFFFF */
  str r1, [r0, #PIT_MR] /* Write mode to PIT Mode Register */

  /* Initialize LED */
init_led:
  /* TODO */

  /* Initializes task structures */
init_tasks:
  /* TODO */

  /* All initializations completed, enable interrupts */
  ENABLE_IRQ
