/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/globals.s"
.include "include/macros.s"

.global mm_alloc_page
.global mm_free_page

/**
 * Allocates a new 4KB page for use. If no free pages are
 * available, this function returns 0.
 *
 * @return r0
 */
mm_alloc_page:
  stmfd sp!, {r1-r6,lr}
  
  /* Find a free page in PAGEBITMAP; Note that free pages
     are marked by 1 in the bitmap so negate is not needed. */
  ldr r0, =PAGEBITMAP
  ldr r4, =PAGEOFFSET
  ldr r4, [r4]
  mov r1, #0
  
  /* Check if we have a recorded last free offset and go
     from there instead. */
  ldr r2, =BITMAP_LAST_FREE_PTR
  ldr r2, [r2]
  cmp r2, #0
  movne r0, r2
  
  DISABLE_IRQ
__find_page:
  /* Find first one bit */
  ldr r2, [r0], #4
  cmp r2, #0
  beq __next_entry
  clz r6, r2
  
__found_page:
  /* Found a free page, compute page number and actual memory
     location. */
  rsb r3, r6, #31
  mov r5, #1
  bic r2, r2, r5, lsl r3
  add r3, r1, r6
  add r3, r4, r3, lsl #12
  
  /* Save this offset for later lookups, so we don't need to
     traverse the whole bitmap again. */
  ldr r5, =BITMAP_LAST_FREE_PTR
  sub r4, r0, #4
  str r4, [r5]
    
  /* Mark page as used */
  str r2, [r0, #-4]
  mov r0, r3
  b __alloc_done
  
__next_entry:
  add r1, r1, #32       /* One entry represents 32 pages */
  cmp r1, #MAXPAGES     /* Check if we are done */
  blo __find_page       /* If not, repeat */
  
  /* No free pages have been found */
  mov r0, #0

__alloc_done:
  ENABLE_IRQ
  
  ldmfd sp!, {r1-r6,pc}

/**
 * Frees a previously allocated page.
 *
 * @param r0 Page address
 */
mm_free_page:
  stmfd sp!, {r0-r4,lr}
  
  /* Compute page address and bitmap offset */
  ldr r2, =PAGEBITMAP
  ldr r1, =PAGEOFFSET
  ldr r1, [r1]
  bic r0, r0, #0xFF
  bic r0, r0, #0xF00
  subs r0, r0, r1
  bmi __done
  
  /* Check if address is too high */
  add r1, r1, #(MAXPAGES << 12)
  cmp r0, r1
  bhs __done
  
  /* Memory address is valid, compute bitmap offset */
  mov r0, r0, lsr #12
  mov r3, r0, lsr #3
  bic r1, r3, #3          /* Align to word boundary */
  sub r3, r0, r1, lsl #3  /* Compute bit offset */
  rsb r3, r3, #31         /* Bits are reversed :) */
  
  DISABLE_IRQ
  /* Modify bitmap */
  ldr r0, [r2, r1]
  mov r4, #1
  orr r0, r0, r4, lsl r3
  str r0, [r2, r1]
  
  /* Save last free offset for later reuse */
  ldr r0, =BITMAP_LAST_FREE_PTR
  ldr r3, [r0]
  add r1, r2, r1
  cmp r1, r3
  strlo r1, [r0]        /* Store if new ptr < current ptr */
  ENABLE_IRQ
  
__done:
  ldmfd sp!, {r0-r4,pc}

.data
.align 2
BITMAP_LAST_FREE_PTR: .long 0
