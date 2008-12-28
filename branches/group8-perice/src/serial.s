/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/G8
 */
.global serial_irq_handler
.global serial_write_request
.global serial_read_request
.global serial_init

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
  ldr r2, =DBGU_BASE
  ldr r4, [r2, #DBGU_SR]

  /* did we receive a new character? */
  tst r4, #1                 /* RXRDY */
  beq __serial_irq_write /* if not, skip to write */

  ldr r0, =SERIAL_RX_WPTR
  ldr r1, [r0]               /* get address to write to */
  ldrb r3, [r2, #DBGU_RHR]
  strb r3, [r1], #1          /* store received char in buffer */
  cmp r1, r0                 /* check if at end of buffer */
  subeq r1, r1, #SERIAL_RX_BUF_SIZE
  str r1, [r0]               /* in which case start over */

  /* check if write ptr 'overflows' */
  add r3, r0, #4
  ldr r3, [r3]
  cmp r1, r3
  ldreq r0, =MSG_SERIAL_PTR_OVERRUN
  beq panic

  /* check if overflow (characters lost) */
  tst r4, #(1 << 5)          /* OVRE */
  ldrne r0, =MSG_SERIAL_OVRE
  bne panic

  /* increment byte counter */
  ldr r2, =SERIAL_RX_NCHARS
  ldr r3, [r2]
  add r3, r3, #1
  str r3, [r2]

  /* process any available read request */
  bl serial_process_read_request

__serial_irq_write:
  /* if TX buffer empty */
  tst r4, #(1 << 11)         /* TXBUFE */
  /* process any available write request */
  blne serial_process_write_request
  
  /* Signal AIC end of interrupt and return */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  POP_CONTEXT

/**
 * Put requesting process in queue and process any
 * existing requests if possible.
 *
 * @param r0 Pointer to source string
 * @param r1 Size (<= 65535)
 * @param r2 printk request (0 = false)
 */
serial_write_request:
  stmfd sp!, {r0-r5,lr}
  mov r4, r0

  bl mm_alloc_page

  /* Prepare queue element */
  cmp r1, #65536                 /* 65535 chars max */
  movhs r1, #65536
  subhs r1, #1
  cmp r2, #0                     /* called from userspace? */
  orrne r1, r1, #SERIAL_RQ_KFLAG /* else mark it kernel */
  str r1, [r0, #SERIAL_RQ_SIZE]
  str r4, [r0, #SERIAL_RQ_BUF]
  mov r4, #0
  str r4, [r0, #SERIAL_RQ_NEXT]
  strne r4, [r0, #SERIAL_RQ_TASK]
  bne __serial_wreq_insert

  LOAD_CURRENT_TCB r3
  str r3, [r0, #SERIAL_RQ_TASK]

__serial_wreq_insert:
  /* Insert into queue === critical section */
  mov r5, r0
  bl irq_disable

  /* Put process on IOWAIT */
  ldreq r2, [r3, #T_FLAG]
  orreq r2, r2, #IOWAIT
  streq r2, [r3, #T_FLAG]

  ldr r1, =SERIAL_WQ_HEAD
  add r2, r1, #4 /* TAIL */
  ldr r3, [r1]
  ldr r4, [r2]
  cmp r3, #0        /* is queue empty? */
  moveq r4, r5
  moveq r3, r5      /* push first request */
  streq r3, [r1]
  strne r5, [r4, #SERIAL_RQ_NEXT]
  movne r4, r5      /* push next request */
  str r4, [r2]

  bl irq_restore    /* End critical section */

  /* process any available read request */
  bl serial_process_write_request

  ldmfd sp!, {r0-r5,pc}

/**
 * Process up to two write requests
 */
serial_process_write_request:
  stmfd sp!, {r0-r4,lr}

  ldr r0, =DBGU_BASE
  ldr r1, [r0, #DBGU_SR]
  tst r1, #(1 << 11)      /* TXBUFE */
  beq __serial_procw_end

  ldr r2, =SERIAL_WQ_HEAD

__serial_procw_loop:
  /* Remove from queue === critical section */
  bl irq_disable

  ldr r3, [r2]
  cmp r3, #0
  beq __serial_procw_end     /* end if queue empty */

  ldr r1, [r3, #SERIAL_RQ_SIZE]

  /* request not already processed? */
  tst r1, #SERIAL_RQ_WFLAG
  beq __serial_procw_write

  /* else store new queue head (or 0) */
  ldr r4, [r3, #SERIAL_RQ_NEXT]
  str r4, [r2]

  tst r1, #SERIAL_RQ_KFLAG

  /* if task request, notify relevant task */
  ldreq r2, [r3, #SERIAL_RQ_TASK]
  ldreq r4, [r2, #T_FLAG]
  biceq r4, r4, #IOWAIT
  streq r4, [r2, #T_FLAG]

  bl irq_restore    /* end critical section */

  tst r1, #SERIAL_RQ_KFLAG

  /* if printk request, free alloc'd space */
  ldrne r0, [r3, #SERIAL_RQ_BUF]
  blne mm_free_page

  /* deallocate queue element */
  mov r0, r3
  bl mm_free_page

  b __serial_procw_loop     /* continue */

__serial_procw_write:
  ldr r2, =DBGU_BASE
  /* check if more requests */
  ldr r4, [r3, #SERIAL_RQ_NEXT]
  cmp r4, #0
  beq __serial_procw_write_one

  /* if so, write next also */
  ldr r1, [r4, #SERIAL_RQ_BUF]
  str r1, [r2, #PDC_TNPR]
  ldr r1, [r4, #SERIAL_RQ_SIZE]
  /*bic r1, r1, #SERIAL_RQ_KFLAG */
  str r1, [r2, #PDC_TNCR]

  /* mark processed */
  orr r1, r1, #SERIAL_RQ_WFLAG
  str r1, [r4, #SERIAL_RQ_SIZE]

__serial_procw_write_one:
  /* write first request */
  ldr r1, [r3, #SERIAL_RQ_BUF]
  str r1, [r2, #PDC_TPR]
  ldr r1, [r3, #SERIAL_RQ_SIZE]
  /* bic r1, r1, #SERIAL_RQ_KFLAG */
  str r1, [r2, #PDC_TCR]

  /* mark processed */
  orr r1, r1, #SERIAL_RQ_WFLAG
  str r1, [r3, #SERIAL_RQ_SIZE]

__serial_procw_end:
  bl irq_restore
  ldmfd sp!, {r0-r4,pc}

/**
 * Put requesting process in queue and process any
 * existing requests if possible.
 *
 * @param r0 Pointer to destination buffer
 * @param r1 Size (<= 65535)
 * @param r2 Read line ('\n') request (0 = false)
 */
serial_read_request:
  stmfd sp!, {r0-r5,lr}
  mov r4, r0

  bl mm_alloc_page

  /* Prepare queue element */
  LOAD_CURRENT_TCB r3
  str r3, [r0, #SERIAL_RQ_TASK]
  str r4, [r0, #SERIAL_RQ_BUF]
  cmp r1, #65536                 /* 65535 chars max */
  movhs r1, #65536
  subhs r1, #1
  cmp r2, #0                     /* is this read line request */
  orrne r1, r1, #SERIAL_RQ_LFLAG /* mark it */
  str r1, [r0, #SERIAL_RQ_SIZE]
  mov r4, #0                     /* don't need if ... */
  str r4, [r0, #SERIAL_RQ_NEXT]  /* alloc'd mem 0x0'd */

  /* Put process on IOWAIT */
  ldr r2, [r3, #T_FLAG]
  orr r2, r2, #IOWAIT
  str r2, [r3, #T_FLAG]

  /* Insert into queue === critical section */
  mov r5, r0
  bl irq_disable

  ldr r1, =SERIAL_RQ_HEAD
  add r2, r1, #4    /* TAIL */
  ldr r3, [r1]
  ldr r4, [r2]
  cmp r3, #0        /* is queue empty? */
  moveq r4, r5
  moveq r3, r5      /* push first request */
  streq r3, [r1]
  strne r5, [r4, #SERIAL_RQ_NEXT]
  movne r4, r5      /* push next request */
  str r4, [r2]

  bl irq_restore    /* End critical section */

  /* process any available read request */
  bl serial_process_read_request

  ldmfd sp!, {r0-r5,pc}

/**
 * Processes first read request on queue
 */
serial_process_read_request:
  stmfd sp!, {r0-r4,lr}

  /* Remove from queue === critical section */
  bl irq_disable

  ldr r3, =SERIAL_RQ_HEAD
  ldr r3, [r3]
  cmp r3, #0
  beq __serial_procr_end     /* end if queue empty */

  ldr r1, [r3, #SERIAL_RQ_SIZE]

  /* check new line flag */
  ands r2, r1, #SERIAL_RQ_LFLAG
  movne r2, #1
  moveq r2, #0
  bic r1, r1, #SERIAL_RQ_LFLAG

  ldr r4, =SERIAL_RX_NCHARS
  ldr r4, [r4]

  bne __serial_procr_line
  
  /* check if enough bytes in buffer */
  cmp r4, r1
  blo __serial_procr_end
  
__serial_procr_line:
  cmp r4, #0
  beq __serial_procr_end

  /* copy bytes from serial buffer to task buffer */
  mov r4, r0
  ldr r0, [r3, #SERIAL_RQ_BUF]
  bl serial_read_bytes

  /* if returned error
  cmp r0, #-1
  mov r0, r4
  beq __serial_procr_end

  /* store new queue head (or 0) */
  ldr r2, =SERIAL_RQ_HEAD
  ldr r4, [r3, #SERIAL_RQ_NEXT]
  str r4, [r2]

  bl irq_restore          /* end critical section */

  /* notify relevant task */
  ldr r1, [r3, #SERIAL_RQ_TASK]
  ldr r4, [r1, #T_FLAG]
  bic r4, r4, #IOWAIT
  str r4, [r1, #T_FLAG]

  /* deallocate queue element */
  mov r0, r3
  bl mm_free_page

  ldmfd sp!, {r0-r4,pc}

__serial_procr_end:
  bl irq_restore
  ldmfd sp!, {r0-r4,pc}

/**
 * Reads number of bytes from serial buffer and
 * writes them to address specified. Optionally it
 * reads one line (that ends with \n). Whichever
 * comes first.
 *
 * @param r0 Pointer to destination buffer
 * @param r1 Size (<=65535)
 * @param r2 Read line (\n) request (0 = false)
 * @return Pointer to destination or -1 if not enough bytes on buffer
 */
serial_read_bytes:
  stmfd sp!, {r0-r8,lr}

  /* check if read line request */
  cmp r2, #0

  ldr r2, =SERIAL_RX_WPTR
  ldr r3, =SERIAL_RX_RPTR
  ldr r5, [r3]
  ldr r7, =SERIAL_RX_NCHARS
  ldr r4, [r7]

  movne r8, #0
  bne __serial_rb_line_loop
  moveq r8, r1

  /* fixed size, copy byte after byte :!? */
__serial_rb_loop:
  cmp r5, r2
  ldreq r5, =SERIAL_RX_BUF
  ldrb r6, [r5], #1
  strb r6, [r0], #1 /* copy byte */
  sub r4, r4, #1
  subs r8, r8, #1
  bne __serial_rb_loop
  b __serial_rb_end

  /* find new line, if any */
__serial_rb_line_loop:
  cmp r5, r2
  ldreq r5, =SERIAL_RX_BUF
  ldrb r6, [r5], #1
  add r8, r8, #1
  cmp r6, #'\n'
  beq __serial_rb_line_copy
  cmp r8, r4
  bne __serial_rb_line_loop
  cmp r1, r8
  bhi __serial_rb_end_err

__serial_rb_line_copy:
  ldr r5, [r3]
  b __serial_rb_loop

__serial_rb_end:
  str r5, [r3]
  str r4, [r7]
  ldmfd sp!, {r0-r6,pc}

__serial_rb_end_err:
  ldmfd sp!, {r0-r6,lr}
  mov r0, #-1
  bx lr

/* Initialize the debug unit so we can output stuff */
serial_init:
  ldr r0, =DBGU_BASE
  mov r1, #0x1A             /* Set baud rate to 115384 (CD=26) */
  str r1, [r0, #DBGU_BRGR]

  /* Enable TX and RX */
  mov r1, #(5 << 4)         /* RXEN|TXEN */
  str r1, [r0, #DBGU_CR]

  /* Set no-parity mode */
  mov r1, #(1 << 11)
  str r1, [r0, #DBGU_MR]

  /* Enable DMA transmition */
  mov r1, #(1 << 8)
  str r1, [r0, #PDC_PTCR]

  /* Enable interrupts */
  mov r1, #(1 << 11)        /* TXBUFE */
  add r1, #1                /* RXRDY  */
  str r1, [r0, #DBGU_IER]

  /* Set receive buffer pointers */
  ldr r0, =SERIAL_RX_BUF
  ldr r1, =SERIAL_RX_WPTR
  ldr r2, =SERIAL_RX_RPTR
  str r0, [r1]
  str r0, [r2]

  /* Set read/write queue pointers */
  ldr r1, =SERIAL_RQ_HEAD
  ldr r2, =SERIAL_WQ_HEAD
  mov r0, #0
  str r0, [r1]
  str r0, [r2]

  /* Reset byte count */
  ldr r3, =SERIAL_RX_NCHARS
  str r0, [r3]

  bx lr


.data
.align /* word-aligns */

.equ SERIAL_RX_BUF_SIZE, 1024

SERIAL_RX_BUF: .space SERIAL_RX_BUF_SIZE, 0xBB
SERIAL_RX_WPTR: .word SERIAL_RX_BUF
SERIAL_RX_RPTR: .word SERIAL_RX_BUF
SERIAL_RX_NCHARS: .word 0

/* Serial read/write queues,
   elements defined in structures.s */
SERIAL_RQ_HEAD: .word 0
SERIAL_RQ_TAIL: .word 0
SERIAL_WQ_HEAD: .word 0
SERIAL_WQ_TAIL: .word 0

MSG_SERIAL_PTR_OVERRUN: .asciz "[SERIAL] Round buffer write address overran read address.\n\r  -> Need larger buffer!"
MSG_SERIAL_OVRE: .asciz "[SERIAL] At least one received character has been lost. Dunno."



