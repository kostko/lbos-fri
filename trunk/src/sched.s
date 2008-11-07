/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/space.s"
.include "include/macros.s"

.text
.code 32

.global dispatch
dispatch:
  /* Task dispatcher */
  b dispatch
