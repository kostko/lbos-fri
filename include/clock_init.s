/* ================================================================
                          SYSTEM CLOCK SETUP
   ================================================================
*/
  ldr r1, =CKGR_PLLAR
  ldr r2, =CKGR_MOR
  ldr r3, =PMC_SR
  ldr r4, =PMC_MCKR

  ldr r0, = 0x0F01
  str r0, [r2]

osc_lp:
  ldr r0, [r3]
  tst r0, #0x01
  beq osc_lp
  
  mov r0, #0x01
  str r0, [r4]

  ldr r0, =0x2000bf00 | ( 124 << 16) | 12  /* 18,432 MHz * 125 / 12 */
  str r0, [r1]

pll_lp:
  ldr r0, [r3]
  tst r0, #0x02
  beq pll_lp

  /* MCK = PCK/4 */
  ldr r0, =0x0202
  str r0, [r4]

mck_lp:
  ldr r0, [r3]
  tst r0, #0x08
  beq mck_lp
