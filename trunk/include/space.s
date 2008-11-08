/* ================================================================
             CONSTROL STRUCTURES SPACE RESERVATION
   ================================================================
*/
.data
.include "include/globals.s"

TINDEX: .space 4    /* Current task index */
TCBLIST: .space 4   /* Pointer to list of TCBs */
CURRENT: .space 4   /* Pointer to current task's TCB */
MCBLIST: .space 4   /* Pointer to free list of MCBs */

/* Task TCB placeholders */
TASK1: .space TCBSIZE
TASK2: .space TCBSIZE
TASK3: .space TCBSIZE
TASK4: .space TCBSIZE
TASK5: .space TCBSIZE
TASK6: .space TCBSIZE
TASK7: .space TCBSIZE
TASK8: .space TCBSIZE
TASK9: .space TCBSIZE
TASK10: .space TCBSIZE

/* Task map table (if you change this, please update MAXTASK in globals.s) */
TASKTAB: .long TASK1
ENDTASKTAB:

/* Place for message control block allocation */
.equ NMCBS, 5
MCBAREA:  .space MCBSIZE*NMCBS

/* Task initialization data (see main.s/task_init) */
.global task_dummy
TASK_INITDATA:
      /* TCB | Program counter | Status register */ 
.long TASK1,   task_dummy,       PSR_MODE_USER
.long 0

/* Kernel stacks (Supervisor and IRQ modes have separate stacks). For
   memory locations see lbos.ind linker script! */
STACK_SUPM_END: .long __STACK_END__ - 256*4
STACK_IRQM_END: .long __STACK_END__
