/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global io_dispatch
.global io_queue_request
.global io_finish_request

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"
.include "include/mmc.s"

.text
.code 32
/**
 * I/O request dispatcher. Do NOT ever call this function when
 * another request might still be in progress!
 */
io_dispatch:
  stmfd sp!, {r1-r7,lr}

__retry_dispatch:
  /* Grab current task pointer */
  LOAD_CURRENT_TCB r5
  
  /* Check if the queue is empty */
  ldr r6, =IOQUEUE_HEAD
  ldr r7, [r6]
  cmp r7, #0
  beq __rq_serviced   /* Queue is empty, just finish */
  
  /* Check busy indicator */
  ldr r0, =IOQUEUE_BUSY
  
  DISABLE_IRQ
  ldr r1, [r0]
  cmp r1, #0
  ldrne r0, =MSG_IO_REENTRY
  bne panic
  
  mov r1, #1
  str r1, [r0]
  ENABLE_IRQ
  
  /* Decode request */
  ldr r4, [r7, #IO_RQ_TASK]
  ldr r3, [r7, #IO_RQ_OPER]
  cmp r3, #IO_OP_READ
  bne __not_read_op
  
  /* Pass READ request to MMC driver */
  ldr r0, [r7, #IO_RQ_ADDR]
  ldr r1, [r7, #IO_RQ_BUF]
  ldr r2, [r7, #IO_RQ_LEN]
  bl mmc_read_block
  
  /* Check for errors */
  cmp r0, #0
  beq __mmc_finished
  bne __mmc_error
  
__not_read_op:
  cmp r3, #IO_OP_WRITE
  bne __not_write_op
  
  /* Pass WRITE request to MMC driver */
  ldr r0, [r7, #IO_RQ_ADDR]
  ldr r1, [r7, #IO_RQ_BUF]
  ldr r2, [r7, #IO_RQ_LEN]
  bl mmc_write_block
  
  /* Check for errors */
  cmp r0, #0
  beq __mmc_finished
  bne __mmc_error

__not_write_op:
  /* Undefined operation, let's panic */
  ldr r0, =MSG_IO_INVALID_OP
  bl panic

__mmc_error:
  /* Set request status code to last error code */
  str r0, [r7, #IO_RQ_RESULT]
  
  /* Pop request from queue */
  ldr r0, =IOQUEUE_HEAD
  ldr r2, =IOQUEUE_TAIL
  
  DISABLE_IRQ
  ldr r4, [r7, #IO_RQ_NEXT]     /* Load pointer to next request in queue */
  str r4, [r0]                  /* Point head to that request */
  ldr r3, [r2]
  cmp r7, r3                    /* Check if tail points to current request */
  movne r3, #1
  moveq r3, #0
  streq r3, [r2]                /* If so, point tail to NULL */
  
  /* Clear busy indicator */
  ldr r0, =IOQUEUE_BUSY
  mov r2, #0
  str r2, [r0]
  ENABLE_IRQ
  
  /* If there are other requests, retry dispatch */
  cmp r3, #0
  bne __retry_dispatch
  b __rq_serviced

__mmc_finished:
  DISABLE_IRQ
  /* Check if request has been serviced meanwhile */
  ldr r0, [r6]
  cmp r0, r7          /* If queue head has changed, then this request has */
  bne __skip_switch   /* already been serviced, return as usual. */
  
  /* If not, block task that posted the request */
  ldr r2, [r4, #T_FLAG]
  orr r2, r2, #IOWAIT
  str r2, [r4, #T_FLAG]
  
  /* If current task has been blocked by this, switch now */
  cmp r4, r5
  swieq #SYS_NEWTASK
  
__skip_switch:
  ENABLE_IRQ

__rq_serviced:
  ldmfd sp!, {r1-r7,pc}

/**
 * Queues a new request for I/O operation. Blocks current task
 * until request is completed.
 *
 * @param r0 Pointer to request structure
 * @return Zero on success, non-zero on error
 */
io_queue_request:
  stmfd sp!, {r1-r5,lr}
  
  /* Prepare request structure */
  LOAD_CURRENT_TCB r5
  str r5, [r0, #IO_RQ_TASK]
  mov r1, #0
  str r1, [r0, #IO_RQ_NEXT]
  
  ldr r1, =IOQUEUE_HEAD
  ldr r2, =IOQUEUE_TAIL
  
  DISABLE_IRQ
  /* Check if any requests in the queue */
  ldr r3, [r1]  /* r3 holds head pointer */
  ldr r4, [r2]  /* r4 holds tail pointer */
  
  /* Add request to end of queue */
  cmp r4, #0
  strne r0, [r4, #IO_RQ_NEXT]   /* Point prev_last->next to new structure */
  streq r0, [r1]                /* Since queue is empty, point head to new struct */
  str r0, [r2]                  /* Point tail to new structure */
  
  /* If we can continue, do so (queue was empty) */
  beq __io_ready
  
  /* IO is currently busy, immediately block current task */
  ldr r2, [r5, #T_FLAG]
  orr r2, r2, #IOWAIT
  str r2, [r5, #T_FLAG]
  
  /* Since IO is busy, switch to some other task */
  swi #SYS_NEWTASK
  ENABLE_IRQ
  
  /* If we are here, then IO request has been serviced */
  b __io_request_end

__io_ready:
  /* No other requests were the queue, enter io_dispatch */
  ENABLE_IRQ
  bl io_dispatch
  
__io_request_end:
  ldmfd sp!, {r1-r5,pc}

/**
 * Called by MMC IRQ handler to signal end of request. Interrupted
 * task context is available on the stack, interrupts are disabled
 * upon entry.
 *
 * @param r0 Error code or zero on success
 */
io_finish_request:
  mov r5, r0                    /* Store error code for later */
  
  /* Pop request from queue */
  ldr r0, =IOQUEUE_HEAD
  ldr r2, =IOQUEUE_TAIL
  ldr r1, [r0]
  cmp r1, #0                    /* Check if current request is NULL */
  ldreq r0, =MSG_IO_INVALID_RQ
  beq panic                     /* If so, we panic */
  
  ldr r4, [r1, #IO_RQ_NEXT]     /* Load pointer to next request in queue */
  str r4, [r0]                  /* Point head to that request */
  ldr r3, [r2]
  cmp r1, r3                    /* Check if tail points to current request */
  movne r3, #1
  moveq r3, #0
  streq r3, [r2]                /* If so, point tail to NULL */
  
  /* Clear busy indicator */
  ldr r0, =IOQUEUE_BUSY
  mov r2, #0
  str r2, [r0]
  
  /* Mark task as ready to schedule and store error code */
  ldr r0, [r1, #IO_RQ_TASK]
  ldr r2, [r0, #T_FLAG]
  bic r2, r2, #IOWAIT
  str r2, [r0, #T_FLAG]
  
  /* Store potential error code */
  str r5, [r1, #IO_RQ_RESULT]
  
  /* If any requests in queue, branch to io_dispatch */
  cmp r3, #0
  beq __finish_done
  ENABLE_IRQ
  
  bl io_dispatch
  
__finish_done:
  /* Returned from dispatcher or just no more I/O requests, continue
     with the interrupted task. */
  POP_CONTEXT

.data
MSG_IO_INVALID_OP: .asciz "Invalid I/O operation in dispatcher!\n\r"
MSG_IO_REENTRY: .asciz "I/O dispatcher reentered while busy!\n\r"
MSG_IO_INVALID_RQ: .asciz "No active request but io_finish_request called ?!?\n\r"

.align 2
IOQUEUE_HEAD: .long 0
IOQUEUE_TAIL: .long 0

/* Busy indicator */
IOQUEUE_BUSY: .long 0
