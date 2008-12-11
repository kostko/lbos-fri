/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
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
 * @return New task's PID
 */
do_fork:
  /* Allocate new TCB */
  /* Get free PID and use it */
  /* Copy CPU context (to new system stack), set parent PID, set task dispatchable */
  /* Copy all memory allocated by current task */
  /* LAST AND ATOMIC: Insert into list of processes */
  b do_fork
