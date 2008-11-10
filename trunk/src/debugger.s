/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global debugger

.text
.code 32
debugger:
  /* We are now officially screwed, output as much data
     as we can. */
  
  /* Switch to SVC mode to see last registers */
  mov r8, #0x13
  orr r8, r8, #(3 << 6)
  msr cpsr_c, r8
  
__panic_loop:
  b __panic_loop
