/* ================================================================
                             GLOBALS
   ================================================================
*/
.global TASK1
.global TASK2
.global TASK3
.global TINDEX
.global TCBLIST
.global CURRENT
.global MCBLIST
.global TASKTAB
.global NMCBS
.global MCBAREA
.global TIMERQUEUE
.global TIMERFREE
.global CUR_JIFFIES
.global PAGEBITMAP
.global PAGEOFFSET
.global STACK_SUPM_END

.equ MAXPAGES, 3840
.equ MAXTASK, 8
.equ NMCBS, 5