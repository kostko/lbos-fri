/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/globals.s"
.include "include/macros.s"

/* Kmalloc block structure and magic constant */
.equ KM_BLK_Size, 0
.equ KM_BLK_NextPtr, KM_BLK_Size + 4
.equ KM_BLK_Magic, KM_BLK_NextPtr + 4
.equ KM_BLK_SIZEOF, KM_BLK_Magic + 4

/* Used for memory corruption detection */
.equ KMALLOC_MAGIC, 0xDA192FA8

/* Note that bit 0 of KMALLOC_MAGIC is used for free/used selection! */

/* Remaining usable block size when split will no longer be considered */
.equ KM_MIN_SPLIT, 16

.global kmalloc
.global kfree
.global kbrk
.global kmalloc_init

/**
 * Initializes the kernel heap memory allocation.
 */
kmalloc_init:
  stmfd sp!, {r0-r1,lr}
  
  /* Initialize variables */
  ldr r0, =KM_HEAP_BRK
  mov r1, #0xA0000000
  str r1, [r0]
  mov r1, #0
  ldr r0, =KM_HEAP_HEAD
  str r1, [r0]
  
  ldmfd sp!, {r0-r1,pc}

/**
 * Modifies kernel heap size by allocating or deallocating pages
 * to/from heap space in virtual memory.
 *
 * @param r0 Increment in bytes (can be negative)
 * @return Start address of additional heap space
 */
kbrk:
  stmfd sp!, {r1-r8,lr}
  
  /* Disable interrupts */
  bl irq_disable
  mov r8, r0
  
  /* Load current brk value to r2 */
  ldr r3, =KM_HEAP_BRK
  ldr r2, [r3]
  mov r7, r2          /* Save previous brk value for return */
  
  /* Calculate number of pages by ceiling */
  cmp r0, #0
  ldrgt r1, =0xFFF
  addgt r0, r0, r1    /* If r0 > 0 add PAGESIZE - 1 */
  mvn r1, r1          /* Get -PAGESIZE */
  and r0, r0, r1      /* r0 = r0 AND -PAGESIZE */
  
  /* r0 now contains properly ceiled increment */
  cmp r0, #0
  movle r0, r2        /* Return existing value (segment does not shrink) */
  ble __kbrk_done     /* TODO: Deallocate if negative (need to fix kmalloc then!) */
  
  /* Call mm_alloc_page until we have enough pages */
  ldr r6, =KERNEL_L1_TABLE
  ldr r6, [r6]
  mov r5, r0
  
__kbrk_alloc:
  bl mm_alloc_page
  cmp r0, #0
  ldreq r0, =MSG_KM_KBRK_OOM
  beq panic
 
  /* While allocating pages, map each page to virtual memory */
  mov r1, r0            /* r1: Physical address */
  mov r0, r6            /* r0: L1 translation table address */
                        /* r2: Virtual address */
  mov r3, #1            /* r3: Size (in pages) */
  mov r4, #VM_SVC_MODE  /* r4: Mode bits */
  bl vm_map_region
  
  add r2, r2, #4096
  subs r5, r5, #4096
  bne __kbrk_alloc
  
  /* Update brk value and return previous brk value */
  str r2, [r3]
  mov r0, r7
  
__kbrk_done:
  /* Restore interrupts */
  mov r7, r0
  mov r0, r8
  bl irq_restore
  mov r0, r7
  
  ldmfd sp!, {r1-r8,pc}

/**
 * Allocates memory from the kernel heap.
 *
 * @param r0 Number of bytes to allocate
 * @return Start address of newly allocated memory
 */
kmalloc:
  stmfd sp!, {r1-r7,lr}
  
  /* Check if size is zero (return 0 this case) */
  cmp r0, #0
  beq __kmalloc_done
  mov r2, r0
  
  /* Disable interrupts */
  bl irq_disable
  mov r7, r0
  
  /* Check if at least one block has been allocated */
  ldr r3, =KM_HEAP_HEAD
  ldr r3, [r3]
  cmp r3, #0
  bne __kmalloc_got_heap
  
  /* No heap, just call kbrk to give us a slice and use that
     for the first two blocks. */
  add r0, r2, #(KM_BLK_SIZEOF * 2)  /* Compute total size needed for allocation (since */
  bl kbrk                           /* we need space for two block descriptors) */ 
  cmp r0, #0                        /* r0 now holds pointer to newly allocated space */
  beq __kmalloc_done                /* If 0 was returned, we are out of memory */
  
  /* Setup block structure (wilderness block) */
  ldr r4, =KM_HEAP_BRK
  ldr r4, [r4]
  add r3, r0, r2                    /* Wilderness block address = */
  add r3, r3, #KM_BLK_SIZEOF        /* = r0 + bytes + sizeof(malloc_t) */
  sub r4, r4, r3                    /* Wilderness block size = KM_HEAP_BRK - r3 */
  
  str r4, [r3, #KM_BLK_Size]        /* Set block size*/
  mov r4, #0
  str r4, [r3, #KM_BLK_NextPtr]     /* Set next block pointer */
  ldr r4, =KMALLOC_MAGIC            /* Load magic constant */
  orr r4, r4, #0b1                  /* Set block used */
  str r4, [r3, #KM_BLK_Magic]       /* Store magic value and free/used */
  
  /* Setup block structure (actual block) */
  str r2, [r0, #KM_BLK_Size]        /* Set block size */
  str r4, [r0, #KM_BLK_Magic]       /* Store magic value and free/used */
  
  /* Set heap head pointer to the new wilderness block */
  ldr r4, =KM_HEAP_HEAD
  str r3, [r4]
  
  /* Block is allocated, we are done */
  add r0, r0, #KM_BLK_SIZEOF        /* Add size of block header */
  b __kmalloc_done

__kmalloc_got_heap:
  /* Search for a free block (r3 contains pointer to first block) */
  ldr r5, =KMALLOC_MAGIC
  mov r6, #0
  
__kmalloc_find_block:
  cmp r3, #0
  beq __kmalloc_get_wilderness
  ldr r4, [r3, #KM_BLK_Magic]
  and r4, r4, #0b1              /* Extract free/used bit */
  cmp r4, #0
  mov r1, r6                    /* Save previous block address for later (r1) */
  mov r6, r3                    /* Save current block address for later */
  ldrne r3, [r3, #KM_BLK_NextPtr]
  bne __kmalloc_find_block
  
  /* Check if found free block is actually big enough */
  ldr r4, [r3, #KM_BLK_Size]
  cmp r4, r2
  ldrlo r3, [r3, #KM_BLK_NextPtr]
  blo __kmalloc_find_block      /* Too small */
  
  /* Split into two blocks if needed */
  sub r0, r4, r2                /* Calculate number of bytes available */
  sub r0, r0, #KM_BLK_SIZEOF    /* for the next block */
  cmp r0, #KM_MIN_SPLIT         /* Check the result for <= KM_MIN_SPLIT */
  ble __kmalloc_overalloc_blk   /* If not enough space for split, overallocate */
  
  /* Otherwise we can now split the block */
  add r4, r3, r2                /* Calculate next block address in r4 */
  add r4, r4, #KM_BLK_SIZEOF    /* {HEAD1|.......>HEAD2|....} */
  str r2, [r3, #KM_BLK_Size]    /* Resize previous block */
  str r0, [r4, #KM_BLK_Size]    /* Set new block size */
  ldr r0, [r3, #KM_BLK_NextPtr] /* Load pointer to next block */
  str r0, [r4, #KM_BLK_NextPtr] /* Store pointer to next block */
  str r4, [r3, #KM_BLK_NextPtr] /* Update next pointer for current block */

__kmalloc_overalloc_blk:
  /* Block is big enough, let's grab it */
  ldr r0, [r3, #KM_BLK_NextPtr] /* Load current block next pointer */
  str r0, [r1, #KM_BLK_NextPtr] /* Update previous block next pointer */
  
  orr r5, r5, #0b1              /* Set used bit */
  str r5, [r3, #KM_BLK_Magic]   /* Store used bit + magic value */
  add r0, r3, #KM_BLK_SIZEOF    /* Add size of block header */
  b __kmalloc_done              /* And we are done */

__kmalloc_get_wilderness:
  /* If no free blocks are found, call kbrk to get us a larger heap. Old wilderness
     block address is in r6, size of wilderness block is in r4 and address of
     previous free block is in r1. */
  
  sub r0, r2, r4                /* We need to increase heap by r2 - size_of_wild_block */
  add r0, r0, #KM_BLK_SIZEOF    /* plus size of block header (for the wilderness block) */
  bl kbrk                       /* Increase heap */
  cmp r0, #0                    /* r0 now holds pointer to newly allocated space */
  beq __kmalloc_done            /* If 0 was returned, we are out of memory */
  
  /* Allocate old wilderness block as the new block. What remains becomes the
     new wilderness block. */
  ldr r4, =KM_HEAP_BRK
  ldr r4, [r4]
  
  add r3, r6, r2                    /* New wilderness block address (r3) = */
  add r3, r3, #KM_BLK_SIZEOF        /* = r6 + bytes + sizeof(malloc_t) */
  sub r4, r4, r3                    /* Wilderness block size = KM_HEAP_BRK - r3 */
  str r4, [r3, #KM_BLK_Size]        /* Set wilderness block size */
  orr r5, r5, #0b1                  /* Set block used */
  str r5, [r3, #KM_BLK_Magic]       /* Store magic value and free/used */
  str r3, [r5, #KM_BLK_NextPtr]     /* Fix previous free block next pointer */
  
  /* Setup block structure (actual block) */
  str r2, [r6, #KM_BLK_Size]        /* Set block size */
  str r5, [r6, #KM_BLK_Magic]       /* Store magic value and free/used */
  add r0, r6, #KM_BLK_SIZEOF        /* Add size of block header */
  
  /* Block is allocated, we are done */
  
__kmalloc_done:
  /* Restore interrupts */
  mov r6, r0
  mov r0, r7
  bl irq_restore
  mov r0, r6
  
  ldmfd sp!, {r1-r7,pc}

/**
 * Frees an existing memory block.
 *
 * @param r0 Block address
 */
kfree:
  stmfd sp!, {r0-r7,lr}
  
  /* Get block descriptor from block address */
  sub r0, r0, #KM_BLK_SIZEOF
  ldr r1, [r0, #KM_BLK_Magic]
  
  /* Check magic value - if it doesn't match panic now */
  ldr r2, =KMALLOC_MAGIC
  bic r3, r1, #0b1                /* Clear free/used bit */
  cmp r2, r3
  bne __kfree_mem_corruption
  
  /* Mark block as free */
  str r2, [r0, #KM_BLK_Magic]
  mov r6, r0                      /* Store block address for later */
  
  /* Link the block back into the chain at the proper place */
  bl irq_disable
  mov r7, r0
  
  /* Traverse free blocks list, finding a proper place for our
     new block, so the blocks are sorted. */
  ldr r3, =KM_HEAP_HEAD
  ldr r3, [r3]
  mov r4, #0                      /* Initialize previous pointer */
  
__kfree_traverse_blocks:
  cmp r3, #0                      /* We are also done when we reach the end */
  beq __kfree_traverse_done
  cmp r3, r6                      /* Compare freed block address with current */
                                  /* element in the list of free blocks. */
  movlt r4, r3                    /* Set previous block pointer */
  ldrlt r3, [r3, #KM_BLK_NextPtr]
  blt __kfree_traverse_blocks     /* While address is lower, continue traversal */
  
__kfree_traverse_done:
  /* Insert our block at this position */
  str r6, [r4, #KM_BLK_NextPtr]
  str r3, [r6, #KM_BLK_NextPtr]
  
  /* Perform block coalescing */
  ldr r3, =KM_HEAP_HEAD
  ldr r3, [r3]
  
__kfree_coalesce:
  /* Check if next block immediately follows this one */
  ldr r4, [r3, #KM_BLK_NextPtr]
  cmp r4, #0
  beq __kfree_done
  
  /* Calculate next block location and check if it's really there */
  ldr r0, [r3, #KM_BLK_Size]
  add r0, r0, #KM_BLK_SIZEOF
  add r5, r3, r0
  cmp r5, r4
  bne __kfree_coalesce
  
  /* Blocks are sequential, coalesce them */
  ldr r1, [r4, #KM_BLK_Size]      /* Load next block size */
  add r0, r0, r1                  /* Add current block size + sizeof(header) */
  str r0, [r3, #KM_BLK_Size]      /* Increase this block */
  ldr r1, [r4, #KM_BLK_NextPtr]   /* Load next next block pointer */
  str r1, [r3, #KM_BLK_NextPtr]   /* Store next pointer to current block */
  b __kfree_coalesce

__kfree_mem_corruption:
  /* Memory corruption has ocurred (or invalid free) */
  ldr r0, =MSG_KM_INVAL_FREE
  stmfd sp!, {r0,lr}
  bl printk
  ldr r0, =MSG_KM_ERROR
  b panic

__kfree_done:
  mov r0, r7
  bl irq_restore

  ldmfd sp!, {r0-r7,pc}

.data
.align 2
/* Current kernel brk value */
KM_HEAP_BRK: .long 0xA0000000

/* Pointer to head block */
KM_HEAP_HEAD: .long 0

/* Messages */
MSG_KM_KBRK_OOM: .asciz "Out of memory during kernel heap segment increase (kbrk)!\n\r"
MSG_KM_INVAL_FREE: .asciz "Memory corruption attempting to free %x (called from %x)!\n\r"
MSG_KM_ERROR: .asciz "Severe crash in kernel heap memory allocator!\n\r"
