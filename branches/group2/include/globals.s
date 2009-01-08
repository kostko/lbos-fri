/* ================================================================
                             GLOBALS
   ================================================================
*/
.global TASK1
.global TASK2
.global TASK3
.global TASK4
.global TASK5
.global TASK6
.global TASK7
.global TASK8
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
.global Q_LEFT
.global SEMA_TABLES

.equ SCHEDULER, 1  /* If set to 0 weighted round robin scheduler,
                      else (please use 1) priority scheduler is used */
.equ MAXPAGES, 3840
.equ MAXTASK, 8
.equ NMCBS, 5