/* ================================================================
                             USEFUL MACROS
   ================================================================
*/
.macro ENABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  orr r0, r0, #1 << 7   /* Set IRQ disable bit (7) */
  msr cpsr, r0          /* Write r0 to CPSR */
.endm

.macro DISABLE_IRQ
  mrs r0, cpsr          /* Load CPSR to r0 */
  bic r0, r0, #1 << 7   /* Clear IRQ disable bit (7) */
  msr cpsr, r0          /* Write r0 to CPSR */
.endm

.macro LED_ON
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  strne r1, [r0, #PIO_CODR]
.endm

.macro LED_OFF
  ldr r0, =PIOC_BASE
  mov r1, #1 << 1
  strne r1, [r0, #PIO_SODR]
.endm
