/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/G8
 */
.global serial_irq_handler 
.global serial_read_request
.global serial_write_bytes

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/structures.s"
      
.text
.code 32

/**
 * Serial (DBGU unit) character receive interrupt handler.
 */
serial_irq_handler:  
  ldr r0, =SERIAL_RX_WPTR
  ldr r1, [r0]        /* get address to write to */
  ldr r2, =DBGU_BASE
  ldrb r2, [r2, #DBGU_RHR]
  strb r2, [r1], #1   /* store received char in buffer */
  cmp r1, r0          /* check if at end of buffer */
  subeq r1, r1, #SERIAL_RX_BUF_SIZE 
  str r1, [r0]        /* in which case start over */
  /* check if write ptr 'overflows' */
  ldr r2, =SERIAL_RX_RPTR
  ldr r2, [r2]
  cmp r1, r2
  ldreq r0, =MSG_SERIAL_PTR_OVERRUN
  beq panic
  /* process any available read request */
  bl serial_process_read_request
  /* Signal AIC end of interrupt and return */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  POP_CONTEXT

/**
 * Writes number of bytes starting at address to the
 * serial interface using DMA.
 *
 * @param r0 Source string address
 * @param r1 Size <=65535
 */ 
serial_write_bytes:
  stmfd sp!, {r0-r3,lr}  
  ldr r3, =DBGU_BASE
__serial_wb_wait:
  ldr r2, [r3, #PDC_TNCR]
  cmp r2, #0  /* Is there no queued transmission? */
  bne __serial_wb_wait
  ldr r2, [r3, #PDC_TCR]
  cmp r2, #0  /* Is there no active transmission? */
  strne r0, [r3, #PDC_TNPR]
  strne r1, [r3, #PDC_TNCR] /* Pass number of characters to queued */
  streq r0, [r3, #PDC_TPR]
  streq r1, [r3, #PDC_TCR]  /* Pass number of characters to active */
  ldmfd sp!, {r0-r3,pc}

/**
 * Reads number of bytes from serial buffer and 
 * writes them to address specified.
 *
 * @param r0 Pointer to destination buffer
 * @param r1 Size
 * @return Pointer to destination or -1 if not enough bytes on buffer
 */ 
serial_read_bytes:
  stmfd sp!, {r1-r6,lr}
  ldr r2, =SERIAL_RX_WPTR
  ldr r3, =SERIAL_RX_RPTR
  ldr r4, [r2]  
  ldr r5, [r3]  
  /* check if enough bytes in buffer, else return -1 */
  cmp r4, r5
  subhs r6, r4, r5 /* ....RPTR<<<<buffer>>>>>WPTR... */
  cmphs r1, r6     /* size <= buf.len */
  movhi r0, #-1
  bhi __serial_rb_end_err
  cmp r4, r5
  sublo r6, r2, r5 /* <<buffer>>>>>WPTR......RPTR<<< */
  ldrlo r7, =SERIAL_RX_BUF
  sublo r7, r4, r7
  addlo r6, r6, r7
  cmplo r6, r1
  movlo r0, #-1
  blo __serial_rb_end_err
  /* safe state, copy byte after byte :!? */
__serial_rb_loop:
  cmp r5, r2
  ldreq r5, =SERIAL_RX_BUF
  ldrb r6, [r5], #1
  strb r6, [r0], #1 /* copy byte */
  subs r1, r1, #1
  bne __serial_rb_loop
__serial_rb_end:
  str r5, [r3]
  ldmfd sp!, {r1-r6,lr}
  sub r0, r0, r1
  bx lr 
__serial_rb_end_err:
  ldmfd sp!, {r1-r6,pc}

/**
 * Put requesting process in queue and process any
 * existing requests if possible.
 *
 * @param r0 Pointer to destination buffer
 * @param r1 Size
 */
serial_read_request:
  stmfd sp!, {r0-r5,lr}
  mov r2, r0
  bl mm_alloc_page
  LOAD_CURRENT_TCB r3
  str r3, [r0, #SERIAL_RQ_TASK]
  str r2, [r0, #SERIAL_RQ_BUF]
  str r1, [r0, #SERIAL_RQ_SIZE]
  mov r2, #0                    /* don't need if ... */
  str r2, [r0, #SERIAL_RQ_NEXT] /* alloc'd mem 0x0'd */
  ldr r2, [r3, #T_FLAG]
  orr r2, r2, #IOWAIT  /* put process on hold */
  str r2, [r3, #T_FLAG] 
  DISABLE_IRQ /* Insert into queue === critical section */ 
  ldr r1, =SERIAL_RQUEUE_HEAD
  add r2, r1, #4
  ldr r3, [r1]
  ldr r4, [r2]
  cmp r3, #0    /* is queue empty? */ 
  moveq r4, r0
  moveq r3, r0  /* push first request */
  streq r3, [r1]
  strne r0, [r4, #SERIAL_RQ_NEXT]
  movne r4, r0  /* push next request */
  str r4, [r2]
  ENABLE_IRQ
  bl serial_process_read_request
  ldmfd sp!, {r0-r5,pc}

/**
 * Processes first read request on queue
 */
serial_process_read_request:
  stmfd sp!, {r0-r4,lr}
  DISABLE_IRQ /* Remove from queue === critical section */
  ldr r2, =SERIAL_RQUEUE_HEAD  
  ldr r3, [r2]
  cmp r3, #0 /* check if queue empty? */
  beq __serial_proc_end
  ldr r0, [r3, #SERIAL_RQ_BUF]
  ldr r1, [r3, #SERIAL_RQ_SIZE]
  bl serial_read_bytes
  cmp r0, #-1 /* returned with error? */
  beq __serial_proc_end
  ldr r4, [r3, #SERIAL_RQ_NEXT]
  str r4, [r2] /* else delete from queue */
  /* and notify relevant task */
  ldr r1, [r3, #SERIAL_RQ_TASK]
  ldr r4, [r1, #T_FLAG]
  bic r4, r4, #IOWAIT
  str r4, [r1, #T_FLAG]     
  ENABLE_IRQ
  mov r0, r3    
  bl mm_free_page
  ldmfd sp!, {r0-r4,pc}           
__serial_proc_end:
  ENABLE_IRQ
  ldmfd sp!, {r0-r4,pc}
   
.data
.align /* word-aligns */

.equ SERIAL_RX_BUF_SIZE, 1024

SERIAL_RX_BUF: .space SERIAL_RX_BUF_SIZE, 0xBB
SERIAL_RX_WPTR: .word SERIAL_RX_BUF
SERIAL_RX_RPTR: .word SERIAL_RX_BUF
SERIAL_RQUEUE_HEAD: .word 0
SERIAL_RQUEUE_TAIL: .word 0
MSG_SERIAL_PTR_OVERRUN: .asciz "[SERIAL] Round buffer write address overran read address.\n\r  -> Need larger buffer!"



