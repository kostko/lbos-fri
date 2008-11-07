/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.text
.code 32

.global task_dummy
task_dummy:
  b task_dummy
