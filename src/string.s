/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global memcpy
.global memset
.global memcmp
.global strlen

.text
.code 32

/**
 * Copy memory area.
 *
 * @param r0 Destination address
 * @param r1 Source address
 * @param r2 Size
 */
memcpy:
  stmfd sp!, {r0-r3,lr}
  
__mc_loop:
  ldrb r3, [r1], #1
  strb r3, [r0], #1
  subs r2, r2, #1
  bne __mc_loop
  
  ldmfd sp!, {r0-r3,pc}

/**
 * Fill memory with a constant byte.
 *
 * @param r0 Memory address
 * @param r1 Fill byte
 * @param r2 Size
 */
memset:
  stmfd sp!, {r0-r2,lr}

__ms_loop:
  strb r1, [r0], #1
  subs r2, r2, #1
  bne __ms_loop
  
  ldmfd sp!, {r0-r2,pc}

/**
 * Compare memory areas.
 *
 * @param r0 Area #1 address
 * @param r1 Area #2 address
 * @param r2 Size
 * @return r0 Zero if equal, 1 if #1 > #2 and -1 otherwise
 */
memcmp:
  stmfd sp!, {r1-r4,lr}
  
__mcp_loop:
  ldrb r3, [r0], #1
  ldrb r4, [r1], #1
  cmp r3, r4
  movhi r0, #1
  movlo r0, #-1
  bne __mcp_done
  subs r2, r2, #1
  bne __mcp_loop
  
  /* Memory areas are equal */
  mov r0, #0  
  
__mcp_done:
  ldmfd sp!, {r1-r4,pc}

/**
 * Returns NULL terminated string length.
 *
 * @param r0 String address
 * @return String length
 */
strlen:
  stmfd sp!, {r1-r2,lr}
  
  mov r1, #0
  
__sl_loop:
  ldrb r2, [r0], #1
  cmp r2, #0
  addne r1, r1, #1
  bne __sl_loop
  
  mov r0, r1
  ldmfd sp!, {r1-r2,pc}

