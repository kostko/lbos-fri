/* ================================================================
                          GENERAL CONSTANTS
   ================================================================
*/
.equ STACKSIZE, 0x100

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
.equ T_STACK, T_FLAG + 4 + STACKSIZE  /* stack area */
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
                          ERROR CODES
   ================================================================
*/
.equ E_BADSVC, -1     /* Invalid SVC number in SWI */
.equ E_NOMCB, -2      /* No MCB available for request */
.equ E_BADTASK, -3    /* Invalid task number */
.equ E_BADMCB, -4     /* Invalid MCB address on reply */
