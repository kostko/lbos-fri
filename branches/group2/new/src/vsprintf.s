/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global vsprintf                       
/**
 * Variable size printf(char *src [, arg ... ]).
 * Arguments are passed on stack.
 * NOTE: Args are NOT removed from stack when done.
 * 
 * MODIFIER   CONVERTS to    EXPECTS on stack
 *  %d         decimal        number
 *  %x         hexadecimal    number
 *  %c         character      number <= 255
 *  %s         string         pointer to string\0
 *  %%         %              
 *
 * @param r0 Pointer to source null-terminated string
 * @param r1 Pointer to destination buffer
 * @return r0 Number of characters written
 */
vsprintf:
  /* God forbode any more bugs here */
  stmfd sp!, {r2-r7,lr}
  mov r6, r1 /* Use copy of dest */
  add r5, sp, #(12*4) /* sp with args to r5 (distance: 7regs here and 5regs in printk.s. yea, that's wrong(esp if interrupted). propose fix: additional reg arg to hold stack ptr) */
__pf_loop:  
  ldrb r2, [r0], #1
  cmp r2, #0    /* End of Source string? */
__pf_loop_end:
  streqb r2, [r6], #1 /* Write 0x0 ...*/
  subeq r0, r6, r1    /* ... count ...*/ 
  beq __pf_end        /* ..and return.*/
  cmp r2, #'%'  /* Skip unless modifier */
  strneb r2, [r6], #1
  bne __pf_loop
  /* switch(r2){ case } */
  ldrb r2, [r0], #1
  cmp r2, #'d'  /* Decimal */
  beq __pf_dec
  cmp r2, #'x'  /* Hexadecimal */
  beq __pf_hex
  cmp r2, #'c'  /* Character */
  beq __pf_chr
  cmp r2, #'s'  /* String */
  beq __pf_str
  cmp r2, #0    /* Abnormal termination */
  beq __pf_loop_end
  cmp r2, #'%'
  /* Otherwise print '%' (and faulty character) to dest */
  mov r3, #'%'
  strb r3, [r6], #1
  strneb r2, [r6], #1
  b __pf_loop

__pf_dec:
  ldmfd r5!, {r2}
  /* There is no division!?#$% */
  mov r3, #(1 << 31)  /* check sign */
  ands r3, r2, r3
  mov r3, #-1 /* mask */
  eorne r2, r2, r3 
  addne r2, r2, #1    /* two's complement */
  movne r3, #'-'
  strneb r3, [r6], #1 /* write sign */
  movne r3, #-1
  ldr r4, =PF_DEC_BUFFER
  mov r7, r4
_pf_dec_loop:
  subs r2, r2, #10  /* subtract 10 */
  add r3, r3, #1    /* this is the divisor */
  bpl _pf_dec_loop
  add r2, r2, #10   /* reverse one loop */
  add r2, r2, #'0'
  strb r2, [r7], #1 /* write down the new modulo on buffer */
  movs r2, r3  /* copy new divisor, clear and continue */
  mov r3, #-1
  bne _pf_dec_loop
  /* ok, now fetch correct decimal from buffer reversed */
__pf_dec_write:
  ldrb r3, [r7, #-1]!
  strb r3, [r6], #1
  cmp r7, r4
  bne __pf_dec_write
  b __pf_loop

__pf_hex:
  ldmfd r5!, {r2}
  mov r3, #'0'
  strb r3, [r6], #1
  mov r3, #'x'
  strb r3, [r6], #1 /* "0x..." */
  mov r3, #7    /* 8 iterations (8 × 4 bit = 32 bit) */
__pf_hex_loop:
  mov r7, #0xF  /* 0b1111 mask  */
  mov r4, r3, lsl #2     /* get mask */
  and r7, r2, r7, lsl r4 /* apply mask */
  mov r7, r7, ror r4     /* align back to bit_0 */
  add r7, r7, #'0'
  cmp r7, #'9'
  addgt r7, r7, #('A' - '9' - 1)
  strb r7, [r6], #1 /* write character to dest */
  subs r3, r3, #1
  bpl __pf_hex_loop
  b __pf_loop

__pf_chr:
  ldmfd r5!, {r2}
  and r2, r2, #0xFF /* <= 255 */
  strb r2, [r6], #1
  b __pf_loop
  
__pf_str:
  ldmfd r5!, {r3}
__pf_str_loop:
  ldrb r2, [r3], #1
  cmp r2, #0  /* is end? */
  beq __pf_loop
  strb r2, [r6], #1
  b __pf_str_loop

__pf_end:
  ldmfd sp!, {r2-r7,pc}

/* 

       I finally understand where double
            underscores come from.
                                               
                                             */
                                             
PF_DEC_BUFFER: .space 10 /* 2147483647 */                                             
