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
.equ T_TTB, T_PRIO + 4                /* translation table base for this task */
.equ T_CURDIR, T_TTB + 4              /* directory, currently opened by the task */
.equ TCBSIZE, T_CURDIR + 4            /* size of tcb in bytes */



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
.equ SCTX_USR_LR, 0x38
.equ SCTX_SVC_LR, 0x3C
.equ SCTX_PC, 0x40

/* ================================================================
                       MMU RELATED CONSTANTS
                       
   This is merely for easier understanding/flag setting. For 
   further reference see the ARM926EJ-S Technical Reference Manual.
   ================================================================
*/
.equ PAGESIZE, 4*1024                                          /* Pagesize in bytes */
.equ TTBIT, 0x10                                               
.equ SECTION, 0b10                                             /* Section constant */
.equ COARSE, 0b01                                              /* Coarse descriptor const. */
.equ DOMAIN, 0x0 << 5                                          /* Domain; legal values from 0 to F */
.equ USR_ACCESS, 0b11 << 10                                    /* User access */
.equ SVC_ACCESS, 0b01 << 10                                    /* Privileged access */
.equ BUFFERABLE, 0b1 << 2                                      /* Omit these from the descriptor to set not cacheable */
.equ CACHEABLE, 0b1 << 3                                       /* and/or not bufferable */
.equ USR_SUBP_P, 0xFF << 4                                     /* Permissions for subpages. Just leave this alone */
.equ SVC_SUBP_P, 0x55 << 4

.equ MMU_L1_INVALID, 0b00                                      /* L1 invalid bits */
.equ MMU_L2_SMALL_PAGE, 0b10                                   /* L2 small page type */

/* Descriptor flags. */
.equ MMU_KERNEL_FLAGS, DOMAIN | TTBIT| SECTION | SVC_ACCESS    
.equ MMU_TASK_FLAGS_L2, SECTION 
.equ MMU_TASK_FLAGS_L1, DOMAIN | TTBIT | COARSE

/* VM mode bits */
.equ VM_MODE_CACHEABLE, 0b01
.equ VM_MODE_BUFFERABLE, 0b10
.equ VM_MODE_SVC_ACCESS, 0b0100
.equ VM_MODE_USR_ACCESS, 0b1100
.equ VM_MODE_DOMAIN, 0b00000000

/* Frequently used mode combos */
.equ VM_SVC_MODE, VM_MODE_SVC_ACCESS | VM_MODE_DOMAIN
.equ VM_USR_MODE, VM_MODE_USR_ACCESS | VM_MODE_DOMAIN

/* VM mode bit masks */
.equ VM_MODE_M_CB, 0b11               /* [1:0] Cacheable/Bufferable flag */
.equ VM_MODE_M_AP, 0b1100             /* [2:3] Access Permissions */
.equ VM_MODE_M_DOMAIN, 0b11110000     /* [7:4] Domain */

/* Possible abort status codes; there are two possibilities for each source */
.equ ABORT_SRC_ALIGN_A, 0b0001        /* Alignment fault */
.equ ABORT_SRC_ALIGN_B, 0b0011
.equ ABORT_SRC_EXT_TRANSL_A, 0b1100   /* External abort or translation */
.equ ABORT_SRC_EXT_TRANSL_B, 0b1110   
.equ ABORT_SRC_TRANSL_A, 0b0101       /* Translation fault */
.equ ABORT_SRC_TRANSL_B, 0b0111
.equ ABORT_SRC_DOMAIN_A, 0b1001       /* Domain fault */
.equ ABORT_SRC_DOMAIN_B, 0b1011
.equ ABORT_SRC_PERMS_A, 0b1101        /* Permissions fault */
.equ ABORT_SRC_PERMS_B, 0b1111
.equ ABORT_SRC_EXT_A, 0b1000          /* External abort */
.equ ABORT_SRC_EXT_B, 0b1010

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
.equ SYS_MKDIR, 10
.equ SYS_REMDIR, 11
.equ SYS_CHDIR, 12
.equ SYS_DIRUP, 13
.equ SYS_OPENF, 14
.equ SYS_DELF, 15
.equ SYS_APPENDF, 16



/* ================================================================
                           DIRECTORY STRUCTURE
   ================================================================
*/
.equ D_NAME,0 														/* name of the directory or file */
.equ D_TYPE, D_NAME + 4 									/* 0 if directory, !0 if file*/
.equ D_PARENT, D_TYPE + 4 								/* parent of this directory or file */
.equ D_CHILD_T, D_PARENT + 4							/* table of all children of this directory, empty if file */
.equ D_SIZE, D_CHILD_T + 4								/* size of this structure */


/* ================================================================
                           DIRECTORY CHILD TABLE
   ================================================================
*/
.equ C_CHILD1, 0  												/* pointer to first child */
.equ C_CHILD2, C_CHILD1 + 4  							/* pointer to second child */
.equ C_CHILD3, C_CHILD2 + 4  							/* pointer to third child */
.equ C_CHILD_T, C_CHILD3 + 4 							/* pointer to next table */


/* ================================================================
                           DIRECTORY ERROR CODES
   ================================================================
*/
.equ E_INDEX, -9  												/* directory error codes index*/
.equ E_NO_DIR, E_INDEX - 1								/* no directories left in dirlist */
.equ E_NO_DIR_IN_LIST, E_NO_DIR - 1				/* child table has no dirs in it */
.equ E_NO_CHILD, E_NO_DIR_IN_LIST - 1			/* can't delete dir, if the current dir has no children */
.equ E_DIR_NOT_EXIST, E_NO_CHILD - 1			/* dir that we want to delete doesn't exist */
.equ E_CHILD_EXIST, E_DIR_NOT_EXIST - 1		/* cannot delete dir if it has children */
.equ E_NO_ATR, E_CHILD_EXIST - 1					/* chdir has no input parameters */
.equ E_END_CHILD_T, E_NO_ATR - 1					/* chdir doesn't have requested dir */
.equ E_ROOT_DIRUP, E_END_CHILD_T - 1 			/* dir up while in root folder  */
.equ E_ROOT_DEL, E_ROOT_DIRUP - 1					/* remdir tries to delete root dir */

