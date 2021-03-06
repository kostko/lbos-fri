/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/globals.s"
.include "include/macros.s"

.global mm_init
.global mm_alloc_page
.global mm_free_page
.global mm_alloc_block

/**
 * Initialize memory manager.
 */
mm_init:
  stmfd sp!, {r0-r2,lr}
  
  /* Initialize bitmap with 0xFF (free space) */
  ldr r0, =PAGEBITMAP
  mov r1, #0xFF
  mov r2, #0
  
__mm_init_bitmap:
  strb r1, [r0], #1
  adds r2, r2, #8
  cmp r2, #MAXPAGES
  blo __mm_init_bitmap
  
  ldmfd sp!, {r0-r2,pc}

/**
 * Allocates a new 4KB page for use. If no free pages are
 * available, this function returns 0.
 *
 * @return r0
 */
mm_alloc_page:
  stmfd sp!, {r1-r7,lr}
  
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
  subne r2, r2, r0
  movne r1, r2, lsl #3
  
  /* Disable IRQ and save current state */
  mov r3, r0
  bl irq_disable
  mov r7, r0
  mov r0, r3
  
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
  /* Restore previous state */
  mov r1, r0
  mov r0, r7
  bl irq_restore
  mov r0, r1
  
  ldmfd sp!, {r1-r7,pc}

/**
 * Frees a previously allocated page.
 *
 * @param r0 Page address
 */
mm_free_page:
  stmfd sp!, {r0-r5,lr}
  
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
  
  /* Disable IRQ and save current state */
  bl irq_disable
  mov r5, r0
  
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
  
  /* Restore previous state */
  mov r0, r5
  bl irq_restore
  
__done:
  ldmfd sp!, {r0-r5,pc}

/**
 * Allocates a contiguous memory block 32K in size that is aligned
 * to respective boundaries.
 *
 * @return Address of first allocated page or zero on failure
 */
mm_alloc_block:
  stmfd sp!, {r1-r5,lr}
  
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
  subne r2, r2, r0
  movne r1, r2, lsl #3
  
  /* Disable IRQ and save current state */
  mov r3, r0
  bl irq_disable
  mov r5, r0
  mov r0, r3
  
__mmab_find_block:
  /* Find a completely free block (0xFF) */
  ldrb r2, [r0], #1
  cmp r2, #0xFF
  bne __mmab_next_entry
  
__mmab_found_block:
  /* Found a free block, compute memory location */
  mov r2, r1, lsr #5        /* This mess is needed because */
  mov r2, r2, lsl #6        /* little endian sucks! */
  rsb r3, r1, #24
  add r1, r3, r2
  add r3, r4, r1, lsl #12
    
  /* Mark block of pages as used */
  mov r2, #0x00
  strb r2, [r0, #-1]
  mov r0, r3
  b __mmab_alloc_done
  
__mmab_next_entry:
  add r1, r1, #8        /* One block represents 8 pages */
  cmp r1, #MAXPAGES     /* Check if we are done */
  blo __mmab_find_block /* If not, repeat */
  
  /* No free blocks have been found */
  mov r0, #0

__mmab_alloc_done:
  /* Restore previous state */
  mov r1, r0
  mov r0, r5
  bl irq_restore
  mov r0, r1
  
  ldmfd sp!, {r1-r5,pc}

.data
.align 2
BITMAP_LAST_FREE_PTR: .long 0
