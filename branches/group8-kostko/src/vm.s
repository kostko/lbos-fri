/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/at91sam9260.s"
.include "include/globals.s"
.include "include/structures.s"
.include "include/macros.s"

.global vm_init
.global vm_prepare_task_ttb
.global vm_switch_ttb
.global vm_alloc_translation_table
.global vm_map_region
.global vm_get_phyaddr
.global vm_abort_handler

/* Free blocks structure definition */
.equ VM_FB_NextFreeBlock, 0x00
.equ VM_FB_BlockSize, 0x04

/**
 * Allocates a new translation table. Table contents is completely
 * filled with zeroes. Tables are allocated from two separate linked
 * lists of free spaces (one for each size, so fragmentation is
 * avoided).
 *
 * Each free block contains the following header in first 8 bytes: 
 *   NextFreeBlock - address of next free block in the respective
 *                   linked list. 
 *   BlockSize - size of the current block (always a multiple of
 *               respective table size) 
 *
 * @param r0 Table size (1 for L1, 2 for L2)
 * @return Table address
 */
vm_alloc_translation_table:
  stmfd sp!, {r1-r7,lr}
  
  /* Load proper linked list header and table size */
  cmp r0, #1
  ldreq r1, =VM_L1_FREE_BLOCKS
  moveq r2, #16384
  ldrne r1, =VM_L2_FREE_BLOCKS
  movne r2, #1024
  
  /* Disable IRQs and save state */
  bl irq_disable
  mov r7, r0
  
  /* Check if any block available */
  ldr r3, [r1]
  cmp r3, #0
  ldrne r0, [r3, #VM_FB_BlockSize]
  bne __vmalltt_free_block_avail
  
  /* No free blocks available, get one (currently 32K) */
  bl mm_alloc_block
  cmp r0, #0            /* Check for out of memory condition */
  beq __vmalltt_oom
  
  /* Overwrite linked list header */
  mov r3, r0
  str r3, [r1]
  
  /* Setup block header */
  mov r0, #0
  str r0, [r3, #VM_FB_NextFreeBlock]
  mov r0, #32768
  str r0, [r3, #VM_FB_BlockSize]
  
__vmalltt_free_block_avail:
  /* A block is available (but might not be the right size) */
  cmp r0, r2                        /* r0 contains block size */
  blo __vmalltt_block_size_error
  bhi __vmalltt_split_block

  /* Block is already the right size, just pop from linked list */
  ldr r4, [r3, #VM_FB_NextFreeBlock]
  str r4, [r1]
  mov r0, r3
  b __vmalltt_done

__vmalltt_split_block:
  /* Block is too large, split into two parts - first part is the
     right size, second part is the remainder. */
  add r4, r3, r2                        /* Compute second part offset */
  sub r5, r0, r2                        /* Compute new block size */
  
  ldr r6, [r3, #VM_FB_NextFreeBlock]    /* Load next block address */
  str r6, [r4, #VM_FB_NextFreeBlock]    /* Setup new block header */
  str r5, [r4, #VM_FB_BlockSize]
  
  str r4, [r1]                          /* Overwrite list header */
  mov r0, r3                            /* We have allocated ourselves a block */
  b __vmalltt_done

__vmalltt_oom:
  /* Out of memory during page table block allocation */
  ldr r0, =MSG_VM_TBL_ALLOC_OOM
  bl panic

__vmalltt_block_size_error:
  /* Invalid block size, this should never happen */
  ldr r0, =MSG_VM_TBL_ALLOC_INVAL_SIZE
  bl panic

__vmalltt_done:
  /* Restore previous state */
  mov r1, r0
  mov r0, r7
  bl irq_restore
  
  /* Zero out the allocated block */
  mov r0, r1      /* r0: table start address */
  mov r1, #0x00   /* r1: fill byte */
                  /* r2: table size */
  bl memset
  
  ldmfd sp!, {r1-r7,pc}

/**
 * Frees a previously allocated translation table.
 *
 * @param r0 Table address
 * @param r1 Table type (as with alloc)
 */
vm_free_translation_table:
  stmfd sp!, {r0-r4,lr}
  
  /* TODO */
  
  ldmfd sp!, {r0-r4,pc}

/**
 * Maps a region of physical pages to virtual memory. This
 * will setup at most 256 pages using course L2 descriptor.
 *
 * @param r0 L1 translation table address
 * @param r1 Physical address
 * @param r2 Virtual address
 * @param r3 Size (in pages)
 * @param r4 Mode bits
 * @return Zero on success, non-zero on failure
 */
vm_map_region_coarse:
  stmfd sp!, {r1-r8,lr}
  
  /* Calculate offset in L1 translation table and fetch
     first level descriptor */
  ldr r7, =0xFFF00000             /* Prepare VMA[31:20] mask */
  and r7, r2, r7                  /* Mask other bits */
  ldr r5, [r0, r7, lsr #18]       /* Load descriptor */
    
  /* Check if descriptor does not exist or is an existing
     coarse page descriptor. */
  and r6, r5, #0b11
  cmp r6, #COARSE
  beq __vmmrc_deref_to_l2
  cmp r6, #MMU_L1_INVALID
  movne r0, #1
  bne __vmmrc_done
  
  /* L1 descriptor is marked as invalid, we have to allocate
     a new L2 table and setup the descriptor. */
  mov r6, r0
  mov r0, #2
  bl vm_alloc_translation_table
  
  /* Got a fresh new L2 table space, setup reference in L1 */
  orr r5, r0, #(COARSE | TTBIT)   /* General flags */
  and r8, r4, #VM_MODE_M_DOMAIN
  orr r5, r5, r8, lsl #1          /* Domain */
  str r5, [r6, r7, lsr #18]
  mov r0, r6

__vmmrc_deref_to_l2:
  /* Load L2 table base and setup necesarry descriptors */
  ldr r6, =0xFFFFFC00             /* Prepare L1[31:10] mask */
  and r5, r5, r6                  /* Mask other bits, so r5 contains L2 table address */
  
  /* Calculate starting offset */
  mov r6, #0xFF000                /* Prepare VMA[19:12] mask */
  and r2, r2, r6
  add r5, r5, r2, lsr #12
  
__vmmrc_setup_descriptor:
  orr r2, r1, #MMU_L2_SMALL_PAGE  /* General flags */
  and r6, r4, #VM_MODE_M_CB
  orr r2, r2, r6, lsl #2          /* Cacheable/Bufferable bits */
  and r6, r4, #VM_MODE_M_AP
  orr r2, r2, r6, lsl #2          /* Acess permissions 0 */
  orr r2, r2, r6, lsl #4          /* Acess permissions 1 */
  orr r2, r2, r6, lsl #6          /* Acess permissions 2 */
  orr r2, r2, r6, lsl #8          /* Acess permissions 3 */
  str r2, [r5], #4
  add r1, r1, #4096               /* Offset physical address by one page */
  subs r3, r3, #1
  bne __vmmrc_setup_descriptor
  
  /* Success */
  mov r0, #0

__vmmrc_done:
  ldmfd sp!, {r1-r8,pc}

/**
 * Maps a 1MB region of physical pages to virtual memory using
 * section L1 desctiptors.
 *
 * @param r0 L1 translation table address
 * @param r1 Physical address
 * @param r2 Virtual address
 * @param r3 Size (ignored, always 256 pages)
 * @param r4 Mode bits
 * @return Zero on success, non-zero on failure
 */
vm_map_region_section:
  stmfd sp!, {r1-r8,lr}
  
  /* Calculate offset in L1 translation table and fetch
     first level descriptor */
  ldr r7, =0xFFF00000             /* Prepare VMA[31:20] mask */
  and r1, r1, r7                  /* Mask other bits in PMA */
  and r2, r2, r7                  /* Mask other bits in VMA */
  ldr r5, [r0, r2, lsr #18]       /* Load descriptor */
  
  /* Check if descriptor does not exist or is an existing
     section descriptor. */
  and r6, r5, #0b11
  cmp r6, #SECTION
  beq __vmmrs_overwrite
  cmp r6, #MMU_L1_INVALID
  movne r0, #1
  bne __vmmrs_done
  
__vmmrs_overwrite:
  /* Setup L1 section descriptor */
  orr r1, r1, #(SECTION | TTBIT)      /* General flags */
  and r3, r4, #VM_MODE_M_CB
  orr r1, r1, r3, lsl #2              /* Cacheable/Bufferable bits */
  and r3, r4, #VM_MODE_M_AP
  orr r1, r1, r3, lsl #8              /* Access permissions */
  and r3, r4, #VM_MODE_M_DOMAIN
  orr r1, r1, r3, lsl #1              /* Domain */
  str r1, [r0, r2, lsr #18]
  
  /* Success */
  mov r0, #0
  
__vmmrs_done:
  ldmfd sp!, {r1-r8,pc}

/**
 * Maps a region of physical pages to virtual memory.
 *
 * @param r0 L1 translation table address
 * @param r1 Physical address
 * @param r2 Virtual address
 * @param r3 Size (in pages)
 * @param r4 Mode bits (see VM_MODE_x constants)
 * @return Zero on success, non-zero on failure
 */
vm_map_region:
  stmfd sp!, {r1-r8,lr}
  
  /* Is number of pages less than 256 ? If so, we can simply use
     just one coarse page descriptor. */
  cmp r3, #256
  blo __vmmr_map_course
  
  /* Possibly some section descriptors and some coarse descriptors */
  mov r5, r3, lsr #8      /* Calculate number of sections needed */
  mov r6, r0
  
__vmmr_map_section:
  /* Map a whole section at once */
  mov r0, r6
  bl vm_map_region_section
  cmp r0, #0
  bne __vmmr_map_done
  
  /* Offset physical and virtual addresses by 1M */
  add r1, r1, #(1 << 20)
  add r2, r2, #(1 << 20)
  sub r3, r3, #256
  subs r5, r5, #1
  bne __vmmr_map_section
  
  /* Done with sections, what's left (if anything) is coarse */
  cmp r3, #0
  moveq r0, #0
  beq __vmmr_map_done
  
__vmmr_map_course:
  /* Map remainder using 4K coarse pages */
  bl vm_map_region_coarse

__vmmr_map_done:
  ldmfd sp!, {r1-r8,pc}

/**
 * Returns physical address of some specified virtual address or
 * zero when no mapping exists. This method does things relative
 * to the current task.
 *
 * @param r0 Virtual address
 * @return Physical address
 */
vm_get_phyaddr:
  stmfd sp!, {r1-r5,lr}
  
  /* Get TTB into r1 */
  mrc p15, 0, r1, c2, c0, 0
  
  /* Calculate table offset */
  ldr r2, =0xFFF00000             /* Prepare VMA[31:20] mask */
  and r5, r0, r2                  /* Mask other bits in VMA */
  ldr r3, [r1, r5, lsr #18]       /* Load descriptor */
  
  /* Check if descriptor does not exist or is not supported */
  and r4, r3, #0b11
  cmp r4, #SECTION
  beq __vmgp_section
  cmp r4, #COARSE
  beq __vmgp_coarse
  
  /* Invalid or unsupported descriptor */
  mov r0, #0
  b __vmgp_done

__vmgp_section:
  /* Section descriptor, just combine bits and we have our PMA */
  and r3, r3, r2                  /* Get bits [31:20] */
  mvn r2, r2                      /* Get inverse mask */
  and r0, r0, r2                  /* And apply to our VMA */
  orr r0, r3, r0                  /* Combine bits to get PMA */
  b __vmgp_done

__vmgp_coarse:
  /* Coarse page table descriptor, dereference L2 table */
  ldr r2, =0xFFFFFC00             /* Prepare L1[31:10] mask */
  and r3, r3, r2                  /* Mask other bits, so r3 contains L2 table address */
  
  /* Calculate starting offset */
  mov r2, #0xFF000                /* Prepare VMA[19:12] mask */
  and r4, r0, r2
  ldr r1, [r3, r4, lsr #12]       /* Load L2 descriptor */
  
  /* Check if descriptor does not exist or is not supported */
  and r4, r1, #0b11
  cmp r4, #MMU_L2_SMALL_PAGE
  movne r0, #0
  bne __vmgp_done
  
  /* Combine bits to get physical address */
  ldr r4, =0xFFF                  /* Prepare mask */
  bic r1, r1, r4                  /* Clear bits [11:0] */
  and r0, r0, r4                  /* Extract bits [11:0] for VMA */
  orr r0, r1, r0                  /* Combine bits to get PMA */

__vmgp_done:
  ldmfd sp!, {r1-r5,pc}

/**
 * Maps kernel areas into the specified L1 table.
 *
 * @param r0 L1 table address
 */
vm_prepare_kernel_areas:
  stmfd sp!, {r0-r6,lr}
  
  /* Save parameters for later use */
  mov r5, r0
  
  /* Set mappings for CPU exception vectors space */
  mov r0, r5            /* r0: L1 table address */
  mov r1, #0x00000000   /* r1: Physical address */
  mov r2, #0x00000000   /* r2: Virtual address */
  mov r3, #1            /* r3: Size (in pages) */
  mov r4, #VM_SVC_MODE  /* r4: Mode bits */
  bl vm_map_region
  
  /* Set mappings for RAM space */
  mov r0, r5            /* r0: L1 table address */
  mov r1, #0x20000000   /* r1: Physical address */
  mov r2, #0x20000000   /* r2: Virtual address */
  mov r3, #8192         /* r3: Size (in pages) */
  mov r4, #VM_SVC_MODE  /* r4: Mode bits */
  bl vm_map_region
  
  /* Set mappings for peripherals */
  mov r0, r5            /* r0: L1 table address */
  mov r1, #0xF0000000   /* r1: Physical address */
  mov r2, #0xF0000000   /* r2: Virtual address */
  mov r3, #65536        /* r3: Size (in pages) */
  mov r4, #VM_SVC_MODE  /* r4: Mode bits */
  bl vm_map_region
  
  /* Set mappings for kernel heap */
  ldr r4, =VM_KERNEL_HEAP_L2
  ldr r6, [r4]
  cmp r6, #0            /* Check if heap space already mapped */
  bne __vmpka_heap_alloced
  
  /* Allocate a new 32K block for all the tables */
  bl mm_alloc_block
  cmp r0, #0            /* Check for out of memory condition */
  ldreq r0, =MSG_VM_ALLOC_HEAP_TBL_OOM
  beq panic
  
  /* Zero out the whole block */
  mov r6, r0
                        /* r0: Memory address */
  mov r1, #0            /* r1: Fill byte */
  mov r2, #0x8000       /* r2: Size (32K) */
  bl memset
  
  /* We now have our heap table space */
  str r6, [r4]

__vmpka_heap_alloced:
  /* We have to create the mappings */
  mov r2, #0xA00        /* Kernel heap start address */
  mov r3, #32           /* Number of L1 descriptors (for 32MB) */
  
__vmpka_heap_create_l1:
  /* Now just map it in L1 (r6 holds L2 table address) */
  orr r0, r6, #(COARSE | TTBIT)   /* General flags, domain is 0 */
  str r0, [r5, r2, lsl #2]
  
  add r6, r6, #1024     /* L2 tables are 1024 bytes long */
  add r2, r2, #1
  subs r3, r3, #1
  bne __vmpka_heap_create_l1
  
  ldmfd sp!, {r0-r6,pc}

/**
 * Sets up task's translation tables.
 *
 * @param r0 Task start address (properly aligned)
 * @param r1 Task size in pages
 * @return Task's TTB
 */
vm_prepare_task_ttb:
  stmfd sp!, {r1-r8,lr}
  
  /* Save parameters for later use */
  mov r6, r0
  mov r7, r1
  
  /* Allocate a fresh L1 table for our task */
  mov r0, #1
  bl vm_alloc_translation_table
  mov r5, r0
  
  /* Set kernel mappings */
  mov r0, r5            /* r0: L1 table address */
  bl vm_prepare_kernel_areas
  
  /* Set mappings for task-specific space */
  mov r0, r5            /* r0: L1 table address */
  mov r1, r6            /* r1: Physical address */
  mov r2, #0x30000000   /* r2: Virtual address */
  mov r3, r7            /* r3: Size (in pages) */
  mov r4, #VM_USR_MODE  /* r4: Mode bits */
  bl vm_map_region
  
  /* Return task's TTB */
  mov r0, r5
  
  ldmfd sp!, {r1-r8,pc}

/**
 * Inits the MMU and sets the Translation Table Base (address given in r0). 
 * 
 * @param r0 Translation Table Base
 */
vm_switch_ttb:
  stmfd sp!, {r0-r1, lr}
  
  mov r1, #0
  mcr p15, 0, r1, c7, c10, 4     /* Drain the write buffer */
  mcr p15, 0, r0, c2, c0, 0      /* Set the new TTB */
  mcr p15, 0, r1, c7, c7, 0      /* Invalidate caches */
  mcr p15, 0, r1, c8, c7, 0      /* Invalidate TLBs */
  
  mrc p15, 0, r0, c1, c0, 0      
  bic r0, r0, #(0x1 << 12)       /* Ensure I Cache disabled */
  bic r0, r0, #(0x1 << 2)        /* Ensure D Cache disabled */
  orr r0, r0, #0x1               /* Enable MMU before scatter loading */
  mcr p15, 0, r0, c1, c0, 0     
                                    
  /* Make sure that the pipeline does not contain anything
     that could cause an invalid address access. */
  nop  
  nop
  nop
   
  /* Enable instruction and data caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 << 12)      /* Instruction cache bit */
  orr r0, r0, #(0x1 << 2)       /* Data cache bit */
  mcr p15, 0, r0, c1, c0, 0
  
  ldmfd sp!, {r0-r1, pc}

/**
 * Initialize the virtual memory. After this function returns MMU
 * will be enabled and programmed with identity maps.
 */
vm_init:
  stmfd sp!, {r0-r1,lr}
  
  /* Allocate ourselves an L1 table and map kernel areas*/
  mov r0, #1            /* r0: Table type (1 = L1) */
  bl vm_alloc_translation_table
  mov r1, r0            /* Save table address to r1 */
  bl vm_prepare_kernel_areas
  
  /* Store table address */
  ldr r0, =KERNEL_L1_TABLE
  str r1, [r0]
  
  /* Disable MMU and invalidate TLBs */
  mrc p15, 0, r0, c1, c0, 0      /* Read CP15:c0 */
  bic r0, r0, #0b1               /* Disable MMU */
  mcr p15, 0, r0, c1, c0, 0      /* Update */
  
  /* Init Translation Table Base for kernel space */
  mcr p15, 0, r1, c2, c0, 0
  
  mov r0, #0
  mcr p15, 0, r0, c7, c7, 0      /* Invalidate caches */
  mcr p15, 0, r0, c8, c7, 0      /* Invalidate TLBs */
  
  mov r0, #0b01                  /* Set Domain 0 to client mode */
  mcr p15, 0, r0, c3, c0, 0    
  
  mrc p15, 0, r0, c1, c0, 0      
  bic r0, r0, #(0x1 << 12)       /* Ensure I Cache disabled */
  bic r0, r0, #(0x1 << 2)        /* Ensure D Cache disabled */
  orr r0, r0, #0x1               /* Enable MMU before scatter loading */
  mcr p15, 0, r0, c1, c0, 0     
                                    
  /* Make sure that the pipeline does not contain anything
     that could cause an invalid address access. */
  nop  
  nop
  nop
  
  /* Enable instruction and data caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 << 12)      /* Instruction cache bit */
  orr r0, r0, #(0x1 << 2)       /* Data cache bit */
  mcr p15, 0, r0, c1, c0, 0
  
  ldmfd sp!, {r0-r1,pc}
 
/**
 * Handles prefetch and data aborts.
 * 
 * Current functionality:
 *  If a task generates an abort due to whatever it gets killed.
 *  If the abort doesn't originate from userspace then panic is called.
 */
vm_abort_handler:
  
  /* Let's try to find out what went wrong */
  
__vm_abort_cause:
  mrc p15, 0, r0, c5, c0, 0          /* Read the Fault Status Register (FSR) */
  ldr r2, =0xFFFFFFF0                /* Mask for extracting the proper bits */
  bic r0, r0, r2                     /* Clear bits [31:4] */
  
  /* Now comes a great deal of tedious compares... */
  
  /* Alignment fault: */
  cmp r0, #ABORT_SRC_ALIGN_A         /* Test both possibilities for this fault */
  cmpne r0, #ABORT_SRC_ALIGN_B
  ldreq r4, =MSG_VM_ABORT_ALIGN      /* Set pointer to message */
  beq __vm_abort_cause_found          /* OK, found the cause */
  
  /* External or translation fault: */
  cmp r0, #ABORT_SRC_EXT_TRANSL_A
  cmpne r0, #ABORT_SRC_EXT_TRANSL_B
  ldreq r4, =MSG_VM_ABORT_EXT_TRANSL 
  beq __vm_abort_cause_found
  
  /* Translation fault: */
  cmp r0, #ABORT_SRC_TRANSL_A
  cmpne r0, #ABORT_SRC_TRANSL_B
  ldreq r4, =MSG_VM_ABORT_TRANSL
  beq __vm_abort_cause_found
  
  /* Domain fault: */
  cmp r0, #ABORT_SRC_DOMAIN_A
  cmpne r0, #ABORT_SRC_DOMAIN_B
  ldreq r4, =MSG_VM_ABORT_DOMAIN
  beq __vm_abort_cause_found
  
  /* Permissions fault: */
  cmp r0, #ABORT_SRC_PERMS_A
  cmpne r0, #ABORT_SRC_PERMS_B
  ldreq r4, =MSG_VM_ABORT_PERMS      
  beq __vm_abort_cause_found
  
  /* External fault: */
  cmp r0, #ABORT_SRC_EXT_A
  cmpne r0, #ABORT_SRC_EXT_B
  ldreq r4, =MSG_VM_ABORT_EXT     
  beq __vm_abort_cause_found
  
  /* No source matched! Set cause to unknown */
  ldr r4, =MSG_VM_ABORT_UNKNOWN
  
__vm_abort_cause_found:
  /* Message in r4. Continue... */
  
  mrs r0, spsr                       /* Fetch the SPSR */
  mrc p15, 0, r1, c6, c0, 0          /* Read the Fault Address Register (FAR) */
  ldr r2, =0xFFFFFFE0                /* Mask for extracting the proper bits */
  
  /* We just check the mode we were in when the abort happened */

  mrs r3, cpsr                        /* Load CPSR to r3 */
  bic r3, r3, #0b11111                /* Clear mode bits */
  orr r3, r3, #PSR_MODE_SVC           /* Set supervisor mode */
  msr cpsr, r3                        /* Write r3 to CPSR */
  
  bic r0, r0, r2                     /* Clear bits [31:5] */
  cmp r0, #PSR_MODE_USER                     
  beq __vm_abort_task                /* Ok, obviously a task is doing some illegal stuff */

__vm_abort_kernel:                   /* Probably a kernel related issue. */
  stmfd sp!, {r4}                    /* Pass probable cause */
  ldr r0, =MSG_VM_KERNEL_ABORT_PK    /* Pass formated message */
  bl printk
  
  ldr r0, =MSG_VM_KERNEL_ABORT       /* Pass the panic msg buffer address in r0 */
  bl panic                           /* Call panic function */

__vm_abort_task:                     /* Task related issue */
  LOAD_CURRENT_TCB r2                /* Get current task TCB */
  ldr r3, =TFINISHED             
  str r3, [r2, #T_FLAG]              /* Set the 'finished' flag; this task is no more */
  
  /* Report evil doings */
  mov r0, #0                         /* This should be the task's PID; zero for now */
  stmfd sp!, {r0, r1, r4}            /* Pass the parameters */
  ldr r0, =MSG_VM_TASK_ABORT         /* ..and the msg buffer address */
  bl printk
  
__vm_abort_done:                     /* Note that this section is executed only on aborts caused by userspace tasks */
  b svc_newtask                      /* Continue */                      
  
.data
.align 2
VM_L1_FREE_BLOCKS: .long 0
VM_L2_FREE_BLOCKS: .long 0

/* Kernel MMU table used only at startup */
KERNEL_L1_TABLE: .long 0

/* L2 translation tables for kernel heap */
VM_KERNEL_HEAP_L2: .long 0

MSG_VM_ALLOC_HEAP_TBL_OOM: .asciz "Out of memory while allocating kernel heap MMU tables!\n\r"
MSG_VM_TBL_ALLOC_OOM: .asciz "Out of memory in VM table allocator!\n\r"
MSG_VM_TBL_ALLOC_INVAL_SIZE: .asciz "Block in allocation table of invalid size!\n\r"
MSG_VM_KERNEL_ABORT: .asciz "[VM] Kernel caused a protection fault.\n\r"
MSG_VM_KERNEL_ABORT_PK: .asciz "[VM] Abort due to kernel bug. Possible cause: %s\n\r"
MSG_VM_TASK_ABORT: .asciz "[VM] Task %d protection fault acessing address %x. Possible cause: %s\n\r"

/* Abort cause messages */
MSG_VM_ABORT_ALIGN: .asciz "Alignment fault"
MSG_VM_ABORT_EXT_TRANSL: .asciz "External abort or translation fault"
MSG_VM_ABORT_TRANSL: .asciz "Translation fault"
MSG_VM_ABORT_DOMAIN: .asciz "Domain fault"
MSG_VM_ABORT_PERMS: .asciz "Permissions fault"
MSG_VM_ABORT_EXT: .asciz "External abort"
MSG_VM_ABORT_UNKNOWN: .asciz "Unknown"
