# Introduction #

When dispatch is called, the scheduler type is chosen. If SCHEDULER is set to 0, jump to wrr\_dispatch, else if the value of SCHEDULER is 1, jump to prio\_dispatch.


# Weighted Round Robin #

  * [WRR description](http://en.wikipedia.org/wiki/Weighted_round_robin)
  * Process' weight is loaded from its TCB's T\_PRIO
  * Process is chosen when it is next in TASKTAB and its T\_FLAG is set to 0
  * If there are no ready processes, jump to no\_dis\_task
  * Loop in no\_dis\_task, until interrupted
  * If process terminates before using all of its time slices, current slice is added to the next process' time
  * Q\_LEFT contains the remaining time for current task
  * Q\_LEFT is decreased each time dispatch is called by PIT
  * At init  Q\_LEFT = 0
  * Interrupts are disabled

# Priority Scheduler #

  * When priority scheduler is chosen, the processes are sorted using [Bubble sort](http://en.wikipedia.org/wiki/Bubblesort)
  * When choosing a new process, always start at the beginning of TCBLIST
  * Choose the first process that has T\_FLAG set to 0
  * The process executes until terminates or it releases the resources  (ex. SVC\_SEND)
  * Q\_LEFT is 0, it is never used
  * If there are no ready processes, jump to no\_dis\_task
  * Loop in no\_dis\_task, until interrupted