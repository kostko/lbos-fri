/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/globals.s"
.include "include/structures.s"
.include "include/macros.s"

/**
 * Returns the next free PID that we can assign to a newly
 * created process.
 *
 * @return Next available PID in r0
 */
get_free_pid:
  stmfd sp!, {r0-r6, lr}
  
  DISABLE_IRQ        /* The next section must be atomic */
  
  /* Load the last PID value allocated */
  ldr r0, =LAST_PID
  ldr r0, [r0]       
  mov r6, r0         /* Make a copy for later */

  ldr r1, =MAX_PID   /* Get the  maximum valid value for the PID */
  ldr r2, =TASKTAB   /* Get TCB list pointer */
  mov r3, #0         /* Task index */
  
  MODULO_INC r0, r1  /* Simply: LAST_PID % MAX_PID */
  
__gfp_loop:
  ldr r4, [r2, r3, LSL #2]    /* Load TCB */
  ldr r5, [r4, #T_PID]        /* Get PID */
  cmp r0, r5                  /* Last pid = current pid ? */
  bne __gfp_pid_ok            /* False */

  MODULO_INC r0, r1           /* True; current pid not unique - increment */
  
__gfp_pid_ok:  
  add r3, r3, #1
  cmp r3, #MAXTASK            /* All tasks checked? */
  blt __gfp_loop
  
  ENABLE_IRQ
  
  ldmfd sp!, {r0-r6, pc}
  
/**
 * Actually executes a process fork.
 *
 * @param r0 Pointer to current task's context on stack
 * @param r1 Pointer to current task's TCB
 * @return New task's PID in r0
 */
do_fork: 
  stmfd sp!, {r1-r10, lr}
  
  mov r9, r0                   /* Save the parameters (damn this assembler!) */
  mov r10, r1 
  
  /* Allocate a page for the child's TCB and system stack */
  bl mm_alloc_page
  mov r8, r0                   /* Save TCB pointer for later */
  cmp r0, #0                   /* Check error condition */
  ldr r0, =MSG_NO_MORE_FREE_PAGES
  bleq panic
  
  /* Get a free PID */
  bl get_free_pid
  mov r7, r0
  str r7, [r8, #T_PID]         /* Set PID */
  
  /* 
   * Copy context and set r0 zero for the child 
   *
   * Note, current register contents:
   * r7 = child PID
   * r8 = child TCB pointer
   * r9 = parent context pointer
   * r10 = parent TCB pointer
   */
  mov r0, #16                  /* Context size */
  /* Move to the begining of child system stack */
  add r1, r8, #PAGESIZE
  sub r1, r1, #1
  add r2, r9, #SCTX_PC         /* Move pointer to the highest address (PC) */
  add r4, r9, #SCTX_REG        /* Register 0 position */
__df_copy_context:
  ldr r3, [r2], #-4            /* Read from parent context */
  cmp r2, r4                   /* Detect r0 copying */
  bne __df_not_r0
  /* Set the "buffer" register to zero. This way the 
     child process gets the return value of 0. */
  mov r3, #0                   
__df_not_r0:
  str r3, [r1], #-4            /* Write to child context */
  subs r0, r0, #1
  bne __df_copy_context
  
  /* 
   * Setup child TCB
   */
  str r1, [r8, #T_SSP]                   /* Store the system stack pointer */
  mov r0, #0
  str r0, [r8, #T_FLAG]                  /* Set dispatchable */
  ldr r0, [r10, #T_USP]                  /* Copy USP */
  str r0, [r8, #T_USP]
  ldr r0, [r10, #T_MAIN_SEGMENT]         /* Copy segment size */
  str r0, [r8, #T_MAIN_SEGMENT]
  
  /* 
   * Copy all memory and setup translation table
   * Good thing we have 12 registers :) ... 
   */
  mov r11, r0                        /* Note: r0 contains the segment size (in pages) */
  mov r0, #1
  bl vm_alloc_translation_table     /* Get L1 table address */
  mov r5, r0
  str r5, [r8, #T_TTB]              /* Save the child TTB */
  
  mov r12, #0x30000000                 /* Process start address */
  ldr r6, [r10, #T_TTB]              /* Get the parents TTB */
  
__df_page_copy:
  /* Actual data copy part: */
  mov r2, r6
  bl vm_get_phyaddr_2              /* Get parent page physical address (see vm.s for parameters) */
  mov r1, r0
  /* Source in r1 */
  bl mm_alloc_page                  /* Alloc a page for the child */
  /* Destination in r0 */
  mov r2, #PAGESIZE
  bl memcpy                         /* Copy data */
  
  /* Translation setup part: */
  mov r1, r0                        /* Physical address same as destination */
  mov r0, r5                        /* L1 table */
  mov r2, r12                       /* Virtual address */
  mov r3, #1                        /* One page */
  mov r4, #VM_USR_MODE              /* User access bits */
  bl vm_map_region
  
  add r12, r12, #PAGESIZE           /* Move to next page */
  sub r11, r11, #1
  bne __df_page_copy
  
  /* LAST AND ATOMIC: Insert into list of processes and increment the number of tasks */
  DISABLE_IRQ
  ldr r0, =TCBLIST
  str r8, [r0, #T_LINK]     /* Add TCB to the list */
  
  /* Increment the number of tasks */
  ldr r0, =NUMTASK
  ldr r1, [r0]
  add r1, r1, #1
  str r1, [r0]
  ENABLE_IRQ
  
  mov r0, r7                /* Return child PID */
  ldmfd sp!, {r1-r10, pc}

MSG_NO_MORE_FREE_PAGES: .asciz "No more free pages!"
