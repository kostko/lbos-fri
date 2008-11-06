/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global sycall_handler
.global svc_newtask

sycall_handler:
  /* System call handler/dispatcher */
  b syscall_handler

/* ================================================================
                       SYSTEM CALLS GO HERE
   ================================================================
*/
svc_newtask:
  /* New task syscall */
  b svc_newtask
