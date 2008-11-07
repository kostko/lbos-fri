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
.global dispatch
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
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  str r1, [r0, #PIO_PER]  /* Enable LED pin control by PIO */
  str r1, [r0, #PIO_OER]  /* Enable output on the I/O line */
  str r1, [r0, #PIO_SODR] /* Turn the LED off for now */

  /* Initializes task structures */
init_tasks:
  ldr r0, =TASK_INITDATA
  ldr r1, =TCBLIST
  
  /* Reset current task index */
  ldr r2, =TINDEX   /* Load TINDEX address */
  mov r3, #0
  str r3, [r2]      /* Write 0 to TINDEX */
  
  /* Initialize all task TCBs */
__init_tcb:
  ldr r2, [r0], #4  /* Load first long move r0 to next field */
  cmp r2, #0
  beq __init_done   /* We are done if r2 is zero */
  
  /* r2 now contains pointer to task's TCB */
  str r3, [r2, #T_USP]    /* Clear task's User Stack Pointer */
  add r4, r2, #T_STACK    /* r4 now holds the task's stack pointer */
  str r3, [r2, #T_FLAG]   /* Mark the task "dispatchable" - clear flags */
  
  /* Push context to stack */
  sub r4, r4, #(13 << 2)  /* Move stack pointer since regs should be there */
  ldr r5, [r0], #4        /* Load task's PC */
  ldr r6, [r0], #4        /* Load task's status register */
  stmfd r4!, {r5,r6}      /* Push task's PC and PSR to the stack */
  
  /* Set r4 to be task's System Stack Pointer */
  str r4, [r2, #T_SSP]
  
  /* Setup TCB linkage */
  str r2, [r1, #T_LINK]   /* Set previous TCB link word; note that first loop
                             iteration only works because T_LINK is 0! */
  mov r1, r2              /* Save current TCB address for later */
  b __init_tcb
  
__init_done:
  /* TCB init completed, clear last T_LINK */
  ldr r3, [r1, #T_LINK]

  /* Initializes message passing structures */
init_messages:
  /* TODO */

  /* All initializations completed */
done:
  ldr r0, =CURRENT
  mov r1, #0
  str r1, [r0]    /* Clear current task */
  
  /* Enter task dispatcher */
  b dispatch
