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
.global spu_irq_handler
.global timer_irq_handler
.global dispatch
.global vm_prepare_task_ttb
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
  
  /* Setup spurious interrupt handler */
  ldr r0, =AIC_BASE
  ldr r1, =spu_irq_handler
  str r1, [r0, #AIC_SPU]
  
  /* Initialize the debug unit so we can output stuff */
init_dbgu:
  ldr r0, =DBGU_BASE
  mov r1, #0x1A             /* Set baud rate to 115384 (CD=26) */
  str r1, [r0, #DBGU_BRGR]
  
  /* Enable TX and RX */
  mov r1, #(1 << 6)
  orr r1, r1, #(1 << 4)
  str r1, [r0, #DBGU_CR]
  
  /* Set no-parity mode */
  mov r1, #(1 << 11)
  str r1, [r0, #DBGU_MR]

  /* Enable DMA transmition - both ways */
  mov r1, #(1 << 8)
  add r1, r1, #1   
  str r1, [r0, #PDC_PTCR]
  
  /* Enable interrupts on character receive */
  /*mov r1, #1
  str r1, [r0, #DBGU_IER]*/
  
  ldr r0, =MSG_PREINIT
  bl printk
  
  /* Initialize the memory manager */
  ldr r0, =MSG_INIT_MM
  bl printk
  bl mm_init
  
  /* Initialize virtual memory */
  ldr r0, =MSG_INIT_VM
  bl printk
  bl vm_init
  
  ldr r0, =MSG_INIT_PER
  bl printk
  
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
  mov r1, #(1 << 1)
  str r1, [r0, #AIC_IECR]
  
  /* Initialize the Periodic Interval Timer (PIT) that will be used by
     the task scheduler. This timer will generate "System Controller
     Interrupt" (peripheral = 1) type interrupt which is shared with
     some other devices (such as the debug unit)! */
init_pit:
  ldr r0, =PIT_BASE
  ldr r1, =PIT_MODE     /* PITEN = 1, PITIEN = 1, PIV = FFFFF */
  str r1, [r0, #PIT_MR] /* Write mode to PIT Mode Register */

  /* Initialize TC0 to be used as time source for kernel timers and
     task delay implementation. */
init_timer:
  /* Setup priorities for TC0 (device 17) */
  ldr r0, =AIC_BASE
  mov r1, #4
  str r1, [r0, #AIC_SMR17]
  
  /* Setup handler address for TC0 */
  ldr r1, =timer_irq_handler
  str r1, [r0, #AIC_SVR17]
  
  /* Enable interrupts for TC0 */
  mov r1, #(1 << 17)
  str r1, [r0, #AIC_IECR]
  
  /* AIC is now programmed, let's setup the timer itself */
  ldr r0, =PMC_BASE
  mov r1, #(1 << 17)        /* Enable TC0 (device 17) */
  str r1, [r0, #PMC_PCER]   /* by configuring PMC */
  
  /* Select TIMER_CLOCK5 (SLCK) */
  ldr r0, =TC0_BASE
  mov r1, #4
  str r1, [r0, #TC_CMR]
  
  /* Enable timer */
  mov r1, #1
  str r1, [r0, #TC_CCR]
  
  /* Enable TC0 interrupts */
  mov r1, #(1 << 4)
  str r1, [r0, #TC_IER]
  
  /* Activate timer */
  mov r1, #(1 << 2)
  str r1, [r0, #TC_CCR]
  
  /* Configure mode (WAVE = 1, WAVESEL =  10) and frequency */
  ldr r1, [r0, #TC_CMR]
  orr r1, r1, #(6 << 13)
  str r1, [r0, #TC_CMR]
  
  mov r1, #65               /* Set frequency to 1 ms */
  str r1, [r0, #TC_RC]      /* by writing to RC */
  
  /* Reset jiffies value */
  ldr r0, =CUR_JIFFIES
  mov r1, #0
  str r1, [r0]
  
  /* Initialize timer queue */
  mov r0, #MAXTASK
  ldr r1, =TIMERAREA
  ldr r2, =TIMERFREE
  str r1, [r2]        /* Point TIMERFREE to first free timer */

__init_timer:
  mov r3, r1              /* Save current timer address */
  add r1, r1, #TMSIZE     /* Compute next timer address */
  str r1, [r3, #TM_LINK]  /* Link current timer to next timer */
  subs r0, r0, #1         /* Decrement timer counter */
  bne __init_timer        /* If no more timer slots, stop */
  
  /* Clear last TM_LINK */
  str r0, [r3, #TM_LINK]

  /* Initialize LED */
init_led:
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  str r1, [r0, #PIO_PER]  /* Enable LED pin control by PIO */
  str r1, [r0, #PIO_OER]  /* Enable output on the I/O line */
  str r1, [r0, #PIO_SODR] /* Turn the LED off for now */

  /* Initializes task structures */
  ldr r0, =MSG_INIT_TCB
  bl printk
init_tasks:
  ldr r0, =TASK_INITDATA
  ldr r1, =TCBLIST
  
  /* Reset current task index */
  ldr r2, =TINDEX   /* Load TINDEX address */
  mov r3, #-1
  str r3, [r2]      /* Write 0 to TINDEX */
  mov r3, #0
  
  /* Initialize all task TCBs */
__init_tcb:
  ldr r2, [r0], #4  /* Load first long move r0 to next field */
  cmp r2, #0
  beq __init_done   /* We are done if r2 is zero */
  
  /* r2 now contains pointer to task's TCB */
  str r3, [r2, #T_USP]    /* Clear task's User Stack Pointer */
  str r3, [r2, #T_FLAG]   /* Mark the task "dispatchable" - clear flags */
  
  /* Allocate system stack for the task */
  mov r7, r0
  bl mm_alloc_page
  mov r4, r0
  mov r0, r7
  
  /* Push context to stack */
  mov r5, #0x30000000     /* Set task's PC */
  str r5, [r4, #-4]!      /* Push task's PC to the stack */
  sub r4, r4, #(13 << 2)  /* Move stack pointer since regs should be there */
  ldr r6, [r0], #4        /* Load task's status register */
  str r6, [r4, #-4]!      /* Push task's PC and PSR to the stack */
  
  /* Set r4 to be task's System Stack Pointer */
  str r4, [r2, #T_SSP]
  
  /* Load task size and physical address and setup TTB */
  mov r7, r0
  mov r8, r1
  ldr r0, [r7], #4        /* r0: Task start address */
  ldr r1, [r7], #4        /* r1: Task size in pages */
  bl vm_prepare_task_ttb
  str r0, [r2, #T_TTB]    /* Store TTB in the TCB */
  mov r0, r7
  mov r1, r8
  
  ldr r8, [r0], #4
  str r8, [r2, #T_PRIO]
  /* Setup TCB linkage */
  str r2, [r1, #T_LINK]   /* Set previous TCB link word; note that first loop */
                          /* iteration only works because T_LINK is 0! */
  
  mov r1, r2             /* Save current TCB address for later */
  b __init_tcb
  
__init_done:
  /* TCB init completed, clear last T_LINK */
  ldr r3, [r1, #T_LINK]

  /* Initializes message passing structures */
  ldr r0, =MSG_INIT_MCB
  bl printk
init_messages:
  mov r0, #(NMCBS - 1)
  ldr r1, =MCBAREA
  ldr r2, =MCBLIST
  str r1, [r2]        /* Point MCBLIST to first free MCB */

__init_mcb:
  mov r3, r1            /* Save current MCB address */
  add r1, r1, #MCBSIZE  /* Compute next MCB address */
  str r1, [r3, #M_LINK] /* Link current MCB to next MCB */
  subs r0, r0, #1       /* Decrement MCB counter */
  bne __init_mcb        /* If no more MCBs, stop */
  
  /* Clear last M_LINK */
  str r0, [r3, #M_LINK]

  /* Initialize Multimedia Memory Card driver */
init_mmc:
  ldr r0, =MSG_INIT_MMC
  bl printk
  
  /* Call the init function */
  bl mmc_init

  /* All initializations completed */
done:
  ldr r0, =MSG_INIT_DONE
  bl printk
  
  
  /* Sorting TCB list by priority using bubble sort */
bubble_sort:
  mov r1, #SCHEDULER  /* Load scheduling discipline */
  cmp r1, #0
  beq end_sort       /* If not priority scheduler, skip sort */

  mov r6, #MAXTASK    /* iteration's counter in r6 */

/* For (MAXTASK - 1) */
__iteration:
  sub r6, r6, #1      /* Decrement iteration counter */
  cmp r6, #1
  bmi end_sort       /* End of sort? */

  ldr r0, =TCBLIST    /* Previous task's T_LINK address in r0 */
  ldr r1, [r0]        /* Task in r1 */

  mov r5, r6          /* counter in r5 */

__compare:
  cmp r5, #1
  bmi __iteration       /* End comparing? */
  sub r5, r5, #1        /* Decrement counter */

  ldr r2, [r1, #T_LINK]  /* Next task in r2 */
  ldr r3, [r1, #T_PRIO]  /* Task's priority in r3 */
  ldr r4, [r2, #T_PRIO]  /* Next task's priority in r4 */

  cmp r3, r4
  bpl __next             /* Next task in list doesn't have higher priority then task */

  ldr r4, [r2, #T_LINK]  /* Task's T_LINK in r4 */
  str r4, [r1, #T_LINK]  /* Task's T_LINK := next task's T_LINK */
  str r2, [r0]           /* Previous task's T_LINK := next task */
  str r1, [r2, #T_LINK]  /* Next task's T_LINK := task */

__next:
  ldr r1, [r0]           /* Old task in r1 */
  add r0, r1, #T_LINK    /* New previous task's T_LINK address */
  ldr r1, [r0]           /* New task */
  b __compare

end_sort:


  ldr r0, =CURRENT
  mov r1, #0
  str r1, [r0]      /* Clear current task */
  
  ldr r1, =Q_LEFT  
  mov r0, #0
  str r0, [r1]
  
  /* Enter task dispatcher */

  b dispatch

.data
/* Messages */
MSG_PREINIT: .asciz "\n\rLBOS-FRI v0.1 for AT91SAM9260/FRI-SMS starting up...\n\r"
MSG_INIT_MM: .asciz ">>> Initializing the memory manager...\n\r"
MSG_INIT_VM: .asciz ">>> Initializing virtual memory...\n\r"
MSG_INIT_PER: .asciz ">>> Initializing peripherals (LED, timers)...\n\r"
MSG_INIT_TCB: .asciz ">>> Initializing tasks...\n\r"
MSG_INIT_MCB: .asciz ">>> Initializing message passing...\n\r"
MSG_INIT_MMC: .asciz ">>> Initializing MMC driver...\n\r"
MSG_INIT_DONE: .asciz "All done! Entering the dispatcher.\n\r"
