# Kernel heap location and usage #

Kernel heap should have preallocated 32MB and be located from virtual memory address `0xA0000000` forward. This requires preallocation of 32 L2 MMU coarse page tables (this fits into one 32K block of physical memory) since heap space needs to be mapped to **same page frames** in all tasks!

This 32K block should be allocated (by using standard MMU block allocation functions) in VM subsystem by `vm_init_kernel_heap` function and saved into the `VM_KERNEL_HEAP_L2` variable.

The kernel heap interface (`kbrk`) needs to perform two basic functions:
  * Increase kernel heap by allocating more physical memory and mapping it to kernel heap space (all allocations are ceiled to 4K).
  * Decrease kernel heap by freeing pages and unmapping them from kernel heap space.

Both functions are needed for later `kmalloc` implementation.

# kmalloc #

A simple linked-list implementation. The following structure describes a single block:
```
struct {
  long size;      // Usable block size (4 bytes)
  long magic;     // Magic value + used bit (4 bytes)
  malloc_t *next; // Pointer to next block (4 bytes)
} malloc_t;

// If the chunk is in use there is no "next" element in the structure!

// If magic value doesn't match, memory corruption has ocurred
.equ KMALLOC_MAGIC, 0xDA192FA8
```

This is a simple implementation and might be replaced in the future. Allocation works as follows:
  * We search for a big enough free block. If a larger block is found, we split it and use the first part for our allocation.
  * The last block in the heap is dubbed the _wildreness block_. It is the only one that can grow arbitrarily using the `kbrk` call and as such should be considered the biggest possible block. When no blocks are found we always:
    * Allocate the wilderness block, increasing the heap via `kbrk` if needed.
    * In the remaining space a new wilderness block is created and properly linked into the list.

Later we might consider implementing _binning_.

# Function prototypes #

```
/**
 * Modifies kernel heap size by allocating or deallocating pages
 * to/from heap space in virtual memory.
 *
 * @param r0 Increment in bytes (can be negative)
 * @return Start address of additional heap space
 */
kbrk:
  /* Call mm_alloc_page until we have enough pages */
  /* While allocating pages, map each page to virtual memory */
  /* If we run out of physical memory, panic now */

/**
 * Allocates memory from the kernel heap.
 *
 * @param r0 Number of bytes to allocate
 * @return Start address of newly allocated memory
 */
kmalloc:
  /* Search for a suitable free block */
  /* If no free blocks are found, call kbrk to get us a larger heap */

/**
 * Frees an existing memory block.
 *
 * @param r0 Block address
 */
kfree:
  /* Get block descriptor from block address */
  /* Check magic value - if it doesn't match panic now */
  /* Mark block as free */
  /* Perform garbage collection over our blocks, merging consecutive
     free block if it can be done */
```