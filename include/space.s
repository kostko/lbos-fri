/* ================================================================
             CONSTROL STRUCTURES SPACE RESERVATION
   ================================================================
*/
TCBLIST: .space 4
CURRENT: .space 4
MCBLIST: .space 4

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

/* Kernel stacks (Supervisor and IRQ modes have separate stacks). For
   memory locations see lbos.ind linker script! */
STACK_SUPM_END: .long __STACK_END__ - 256*4
STACK_IRQM_END: .long __STACK_END__
