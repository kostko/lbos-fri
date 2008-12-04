/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */

/* Include structure definitions and static variables */
.include "include/globals.s"
.include "include/structures.s"

.global vm_prepare_task_ttb
.global vm_switch_ttb
/**
 * @param r0 Pointer to L1 space
 * @param r1 Pointer to L2 space
 * @param r2 Task start address (properly aligned)
 * @param r3 Task size in pages
 */
vm_prepare_task_ttb:
  stmfd sp!, {r0-r8, lr}
  
  ldr r4, =0x21F                  /* Counter for bits [31:20] */
  ldr r5, =MMU_TASK_FLAGS_L1
  ldr r6, =MMU_TASK_FLAGS_L2
  orr r6, r6, #SVC_SUBP_P         /* First set only privileged access */
  
  /* Set mappings for CPU Exception vectors space */
  ldr r7, =MMU_KERNEL_FLAGS       /* Base address is 0x0. */
  str r7, [r0]                    /* Store it to L1 space. */
  
  /* Set mappings for RAM space */                           
  _init_ttb_1:                                                        
    orr r7, r1, r5              /* First level descriptor */        
    str r7, [r0, r4, LSL #2]    /* Store it */
    
    ldr r8, =0xFF               /* Counter for bits [19:12] */
    _init_ttb_2:              
      mov r7, r4, LSL #20
      orr r7, r7, r8, LSL #12
      orr r7, r7, r6            /* Second level descriptor */
      str r7, [r1, r8, LSL #2]  /* Store it */
      
      subs r8, r8, #1
      bpl _init_ttb_2
    
    add r1, r1, #(1 << 10)      /* Set to next L2 table address (1KB apart) */
    sub r4, r4, #1
    
    cmp r4, #(1 << 9)           /* Is the counter >= 0x200 (=start of RAM) */     
    bge _init_ttb_1

    /* We need to grant user access to task space addresses */
  _ptt_set_task_space:
    orr r4, r0, r2, LSR #18
    bic r4, r4, #3              /* r4 will hold the proper level 1 descriptor's addr */
    ldr r5, [r4]                /* Load L1 descr. */
    
    /* This extracts bits [19:12] from the task's address (which is in r2). */
    mov r6, r2, LSR #10
    ldr r7, =0xFFF
    mov r7, r7, LSL #11
    bic r6, r6, r7
    
    ldr r7, =0x3FF
    bic r5, r5, r7              /* Clear bits [9:0] */
    orr r5, r5, r6              /* Combine to get the proper level 2 descriptor address */
    
    ldr r6, [r5]                /* Load it */
    orr r6, r6, #USR_SUBP_P     /* Change flags to grant user access */
    str r6, [r5]                /* Update */ 
    
    add r2, r2, #(0b1 << 12)    /* Move to next page of this task, i.e. increment start address by 4K */
    subs r3, r3, #1             /* Decrement "task size in pages" counter */
    bne _ptt_set_task_space     /* Pages left? */
    
  /* Peripheral table map init; 0xF0000000 - 0xFFFFFFFF */
  ldr r4, =0xFFF
  ldr r5, =MMU_KERNEL_FLAGS

  _periph_L1:
    orr r7, r5, r4, LSL #20
    str r7, [r0, r4, LSL #2]
    
    subs r4, r4, #1
    cmp r4, #0xF00
    bge _periph_L1
  
  ldmfd sp!, {r0-r8, pc}
  
  
/**
 * Inits the MMU and sets the Translation Table Base (address given in r0). 
 * 
 * @param r0 Translation Table Base
 */
vm_switch_ttb:
  stmfd sp!, {r0-r8, lr}
  
  mov r8, r0
  
  /* Disable MMU and invalidate TLBs. */
  mrc p15, 0, r0, c1, c0, 0      /* Read CP15:c0 */
  bic r0, r0, #0b1               /* Disable MMU */
  mcr p15, 0, r0, c1, c0, 0      /* Update */
  
  /* Init Translation Table Base for kernel space */
  mcr p15, 0, r8, c2, c0, 0
  
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
     that could cause an invalid address acces. */
  nop  
  nop
  nop
   
  /* Enable instruction and data caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 << 12)      /* Instruction cache bit */
  orr r0, r0, #(0x1 << 2)       /* Data cache bit */
  mcr p15, 0, r0, c1, c0, 0
  
  ldmfd sp!, {r0-r8, pc}
