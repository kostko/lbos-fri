# Virtual memory layout #
| **VA** | **PA** | **Size** | **Level** | **Description** |
|:-------|:-------|:---------|:----------|:----------------|
| 0x20000000 | 0x20000000 | 32M | 1 | Kernel accessible SDRAM (identity map). |
| 0x30000000 | _per-task_ | 256K | 2 | Per-task mapped space. |
| 0xA0000000 | _dynamic_ | 32M | 2 | Kernel heap. Page frames that kernel is using are mapped here. |
| 0xF0000000 | 0xF0000000 | 256M | 1 | Internal peripherals (identity map). |
| 0xFFFF0000 | 0x00000000 | 4K | 2 | High CPU exception vectors. |

Table types:
  * **Level 1** - section descriptors (per 1M block).
  * **Level 2** - coarse page descriptors (4K blocks)

Notes:
  * Every address not listed in the above table **must** be marked invalid so it generates a page fault.
  * Since there is always only 32MB of RAM on the FRI-SMS board, we can simply identity map it, so we can access it without problems in the kernel.
  * We have to set bit 13 in CP15 register c1 to enable high CPU exception vectors.

# Dynamic table block allocation #

Two linked lists, one for free blocks for L1 tables, the other for free blocks for L2 tables:

```
VM_L1_FREE_BLOCKS: .long 0
VM_L2_FREE_BLOCKS: .long 0
```

Lists are kept separate to avoid fragmentation. Each free block contains the following header in first 8 bytes:
  * **NextFreeBlock** - address of next free block in the respective linked list.
  * **BlockSize** - size of the current block (always a multiple of respective table size)

When we need a new block for L1 or L2 table, we do the following:
  1. Find a free block in the respective linked list. If the list contains a block that is bigger than what we need, we split it into two parts (one is the size we need, the other is the remainder). If there are no free blocks available (only when `VM_Lx_FREE_BLOCK` points to 0), we proceed with point 2.
  1. When there are no free blocks available, we call `mm_alloc_block` function, so we get a contiguous block of memory (currently 32K). We insert that block into the respecitve linked list and repeat point 1.

When the time comes to free the table, we just put it back to the beginning of the linked list (and write the proper header into it).

# Function to generate mappings #
```
/**
 * @param r0 Pointer to L1 space
 * @param r1 Pointer to L2 space
 * @param r2 Task start address (properly aligned)
 * @param r3 Task size in pages
 */
prepare_task_ttb:
  /* Generate identity map for L1 */
  /* Generate identity map for L2 */
  /* [(Shift task start address >> 18) AND NOT(3)] OR [L1 space] */
  /* Setup pointer to L2 coarse page descriptor */
  /* [(Shift task start address >> 12) AND 0xFF] OR [L2 space] */
  /* Setup identity map for r3 number of pages */
```

Call prepare\_task\_ttb in main (tcb init), table addresses currently staticly defined and listed in task init table (space.s). This function should be put into _memory.s_ (or _vm.s_ if it is found more suitable).

# Task Control Block entries #
T\_TTB field in TCB. Dispatcher switches MMU TTB value on context switch. We also **must** flush data and instruction caches, otherwise wierd stuff might happen.

# Fault handler #
Fault handler (DATA/FETCH abort):
  * When a _userspace task_ causes a problem, it should be killed and a message outputed via DBGU (something like `"[VM] Task %d protection fault acessing address %x."`)
  * When the fault ocurrs in _kernel mode_ the fault handler should cause a panic.

# Nasty task #
Add a task that messes around with (unauthorized) memory accesses.