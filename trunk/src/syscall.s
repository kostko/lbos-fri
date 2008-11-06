/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global sycall_handler

sycall_handler:
  /* System call handler/dispatcher */
  b syscall_handler