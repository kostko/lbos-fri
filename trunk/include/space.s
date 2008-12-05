/* ================================================================
             CONSTROL STRUCTURES SPACE RESERVATION
   ================================================================
*/
.data
.include "include/globals.s"
.include "include/structures.s"

.long 0xEFBEADDE

.align 2
TINDEX: .space 4    /* Current task index */
TCBLIST: .space 4   /* Pointer to list of TCBs */
CURRENT: .space 4   /* Pointer to current task's TCB */
MCBLIST: .space 4   /* Pointer to free list of MCBs */

/* Task TCB placeholders */
.align 2
TASK1: .space TCBSIZE
TASK2: .space TCBSIZE
TASK3: .space TCBSIZE

/* Task map table (if you change this, please update MAXTASK in globals.s) */
.align 2
TASKTAB: .long TASK1, TASK2, TASK3
ENDTASKTAB:

/* Place for message control block allocation */
MCBAREA:  .space MCBSIZE*NMCBS

/* Task initialization data (see main.s/task_init) */
.global task_dummy
.global task_msgtest
.align 2
TASK_INITDATA:
      /* TCB | Program counter | Status register | Task address  | Task size in pages (currently statically defined) */ 
.long TASK1,   task_dummy,       PSR_MODE_USER,    _task1_paddr,   256*1024 / PAGESIZE
.long TASK2,   task_msgtest,     PSR_MODE_USER,    _task2_paddr,   256*1024 / PAGESIZE
.long TASK3,   task_iotest,      PSR_MODE_USER,    _task3_paddr,   256*1024 / PAGESIZE
.long 0

/* WARNING ABOUT ADDING NEW TASKS
 *
 * If you wish to add more tasks, you need to edit the linker script and
 * define a new task section. Note that all task sections must be aligned
 * to proper 256K boundaries! Also don't forget to increment MAXTASK in
 * globsls.s otherwise tasks will not be scheduled.
 */


/* Timer structures */
.align 2
TIMERAREA: .space TMSIZE*MAXTASK  /* Area for timer alocation */
TIMERFREE: .space 4               /* Pointer to list of free timers */
TIMERQUEUE: .space 4              /* Timer queue pending firing */
CUR_JIFFIES: .space 4             /* Current jiffies value */

/* Terminal I/O structures */
.align 2
TERMDESC: .space TERMSIZE

/* Memory allocation structures */
.align 2
PAGEBITMAP: .space MAXPAGES/8, 255
PAGEOFFSET: .long __PAGE_OFFSET__

/* Kernel stacks (Supervisor and IRQ modes have separate stacks). For
   memory locations see layout.ind linker script! */
.align 2
STACK_SUPM_END: .long __STACK_END__ - STACK_SIZE*4
STACK_IRQM_END: .long __STACK_END__

/* Messages */
MSG_PREINIT: .asciz "\n\rLBOS-FRI v0.1 for AT91SAM9260/FRI-SMS starting up...\n\r"
MSG_INIT_MM: .asciz ">>> Initializing the memory manager...\n\r"
MSG_INIT_PER: .asciz ">>> Initializing peripherals (LED, timers)...\n\r"
MSG_INIT_TCB: .asciz ">>> Initializing tasks...\n\r"
MSG_INIT_MCB: .asciz ">>> Initializing message passing...\n\r"
MSG_INIT_MMC: .asciz ">>> Initializing MMC driver...\n\r"
MSG_INIT_DONE: .asciz "All done! Entering the dispatcher.\n\r"
