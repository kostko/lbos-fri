/* ================================================================
                          GENERAL CONSTANTS
   ================================================================
*/
.equ STACK_SIZE, 0x1000

/* ================================================================
                TASK CONTROL BLOCK STRUCTURE / OFFSETS 
   ================================================================
*/
.equ T_LINK, 0                        /* link word for task list thread */
.equ T_MSG, T_LINK + 4                /* link to waiting messages */
.equ T_RPLY, T_MSG + 4                /* link to message received */
.equ T_USP, T_RPLY + 4                /* user stack pointer area */
.equ T_SSP, T_USP + 4                 /* system stack pointer area */
.equ T_FLAG, T_SSP + 4                /* flag word */
.equ T_PRIO, T_FLAG + 4               /* task priority or something */
.equ T_STACK, T_PRIO + 4 + STACK_SIZE /* end of stack area */
.equ TCBSIZE, T_STACK                 /* size of tcb in bytes */


/* ================================================================
             MESSAGE CONTROL BLOCK STRUCTURE / OFFSETS 
   ================================================================
*/
.equ M_LINK, 0             /* link word */
.equ M_BUFF, M_LINK + 4    /* buffer address for i/o */
.equ M_COUNT, M_BUFF + 4   /* 32-bit count */
.equ M_RTCB, M_COUNT + 4   /* requesting tcb address */
.equ M_STAT, M_RTCB + 4    /* status word */
.equ MCBSIZE, M_STAT + 4   /* size of mcb */

/* ================================================================
                        TIMER CONTROL STRUCTURE
   ================================================================
*/
.equ TM_LINK, 0
.equ TM_COUNT, TM_LINK + 4
.equ TM_TASK, TM_COUNT + 4
.equ TMSIZE, TM_TASK + 4

/* ================================================================
                        TERMINAL DESCRIPTOR
   ================================================================
*/
.equ TERM_IBUF, 0
.equ TERM_IBUF_START, TERM_IBUF + 4
.equ TERM_IBUF_END, TERM_IBUF_START + 4
.equ TERM_OBUF, TERM_IBUF_END + 4
.equ TERM_OBUF_START, TERM_OBUF + 4
.equ TERM_OBUF_END, TERM_OBUF_START + 4
.equ TERMSIZE, TERM_OBUF_END + 4

/* ================================================================
                       I/O REQUEST DESCRIPTOR
   ================================================================
*/
.equ IO_RQ_OPER, 0
.equ IO_RQ_ADDR, IO_RQ_OPER + 4
.equ IO_RQ_BUF, IO_RQ_ADDR + 4
.equ IO_RQ_LEN, IO_RQ_BUF + 4
.equ IO_RQ_TASK, IO_RQ_LEN + 4
.equ IO_RQ_RESULT, IO_RQ_TASK + 4
.equ IO_RQ_NEXT, IO_RQ_RESULT + 4
.equ IORQSIZE, IO_RQ_NEXT + 4

.equ IO_OP_READ, 1
.equ IO_OP_WRITE, 2

/* ================================================================
                           PROCESS FLAGS
   ================================================================
*/
.equ IWAIT, 1             /* Waiting on interrupt */
.equ MWAIT, 2             /* Waiting on message completion */
.equ RWAIT, 4             /* Waiting on message receipt */
.equ TWAIT, 8             /* Waiting on timer */
.equ IOWAIT, 16           /* Waiting on IO */
.equ TFINISHED, (1 << 31) /* Task has finished execution */

/* ================================================================
                          ERROR CODES
   ================================================================
*/
.equ E_BADSVC, -1     /* Invalid SVC number in SWI */
.equ E_NOMCB, -2      /* No MCB available for request */
.equ E_BADTASK, -3    /* Invalid task number */
.equ E_BADMCB, -4     /* Invalid MCB address on reply */

/* ================================================================
                       ON-STACK CONTEXT LAYOUT
                     (see README.txt for details)
   ================================================================
*/
.equ SCTX_PSR, 0x00
.equ SCTX_REG, 0x04
.equ SCTX_PC, 0x38

/* ================================================================
                    SYSCALL NUMBERS FOR USERSPACE
   ================================================================
*/
.equ SYS_NEWTASK, 0
.equ SYS_PRINTLN, 1
.equ SYS_DELAY, 2
.equ SYS_SEND, 3
.equ SYS_RECV, 4
.equ SYS_REPLY, 5
.equ SYS_LED, 6
.equ SYS_MMC_READ, 7
.equ SYS_MMC_WRITE, 8
.equ SYS_EXIT, 9
