/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global mmc_init
.global printk

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"
.include "include/mmc.s"

.text
.code 32
/**
 * Performs MCI initialization sequence and tries to detect
 * MMC cards. If no cards are found on the bus, MMC support is
 * deactivated. Only the first card to reply is identified and
 * used by the system.
 */
mmc_init:
  stmfd sp!, {r0-r6,lr}
  
  /* Configure PMC for MCI CLK (device 9) */
  ldr r0, =PMC_BASE
  mov r1, #(1 << 9)
  str r1, [r0, #PMC_PCER]
  
  /* Configure PIO for MCI */
  ldr r1, =PIOA_BASE
  mov r0, #8
  mov r2, #0            /* Disable pull-up resistor */
  bl __mmc_setup_pin_A  /* PA8 - MCCK */
  
  mov r0, #7
  mov r2, #1            /* Enable pull-up resistor */
  bl __mmc_setup_pin_A  /* PA7 - MCCDA */
  mov r0, #6
  bl __mmc_setup_pin_A  /* PA6 - MCDA0 */
  mov r0, #9
  bl __mmc_setup_pin_A  /* PA9 - MCDA1 */
  mov r0, #10
  bl __mmc_setup_pin_A  /* PA10 - MCDA2 */
  mov r0, #11
  bl __mmc_setup_pin_A  /* PA11 - MCDA3 */
  
  /* Configure PDC (DMA controller) */
  ldr r3, =MCI_BASE
  mov r0, #(1 << 1)       /* Set RXDIS bit */
  orr r0, r0, #(1 << 9)   /* Set TXDIS bit */
  str r0, [r3, #PDC_PTCR]
  
  /* Reset all transfer descriptors */
  mov r0, #0
  str r0, [r3, #PDC_TNPR]
  str r0, [r3, #PDC_TNCR]
  str r0, [r3, #PDC_RNPR]
  str r0, [r3, #PDC_RNCR]
  str r0, [r3, #PDC_TPR]
  str r0, [r3, #PDC_TCR]
  str r0, [r3, #PDC_RPR]
  str r0, [r3, #PDC_RCR]
  
  mov r0, #1              /* Set RXEN bit */
  orr r0, r0, #(1 << 8)   /* Set TXEN bit */
  str r0, [r3, #PDC_PTCR]
  
  /* Configure AIC */
  ldr r3, =AIC_BASE
  mov r0, #(1 << 9)
  str r0, [r3, #AIC_IDCR] /* Disable the interrupt */
  ldr r1, =mmc_irq_handler
  str r1, [r3, #AIC_SVR9] /* Set irq handler vector */
  mov r1, #7
  str r1, [r3, #AIC_SMR9] /* Set priority */
  str r0, [r3, #AIC_ICCR] /* Clear interrupt */
  str r0, [r3, #AIC_IECR] /* Enable interrupt */
  
  /* Configure MCI */
  ldr r3, =MCI_BASE
  mov r0, #(1 << 7)       /* Set SWRST bit (reset MCI) */
  orr r0, r0, #(1 << 1)   /* Set MCIDIS bit (MCI disable) */
  str r0, [r3, #MCI_CR]
  
  mov r0, #1              /* Set MCIEN bit (MCI enable) */
  str r0, [r3, #MCI_CR]
  
  sub r0, r0, #2          /* Get 0xFFFFFFFF */
  str r0, [r3, #MCI_IDR]  /* Disable all interrupts */
  
  mov r0, #1              /* Number of cycles before mul is 1 */
  orr r0, r0, #(7 << 4)   /* Set multiplier to 1M */
  str r0, [r3, #MCI_DTOR]
  
  mov r0, #0x4a
  orr r0, r0, #(0x83 << 8)  /* 400kHz for MCK = 60MHz */
  str r0, [r3, #MCI_MR]
  
  mov r0, #0
  str r0, [r3, #MCI_SDCR] /* SLOT A, 1 bit bus */
  
  /* Wait for the MCI to become ready */
  mov r0, #0x100000
  bl mci_wait_ready
  
  /* Reset all MMC cards to idle state */
  mov r0, #MMC_GO_IDLE_STATE
  orr r0, r0, #MCI_CMDR_OPDCMD
  bl mmc_send_command_with_polling
  
  /* Ask cards to send their operations conditions */
  bl mmc_power_up_cards
  
  /* Check for errors */
  cmp r0, #0
  ldrne r0, =MSG_MMC_INIT_FAILED
  bne __mmc_init_failed
  
  ldr r0, =MSG_MMC_POWERON
  bl printk
  
  /* Identify cards on the bus, fetch their properties and store
     them in a list */
  bl mmc_discover_cards
  
  /* Check for errors */
  cmp r0, #0
  ldrne r0, =MSG_MMC_DISCOVER_FAILED
  bne __mmc_init_failed
  
  /* Display first discovered MMC card info */
  ldr r0, =MSG_MMC_DISCOVER_OK
  bl printk
  /* TODO */
  
  b __mmc_init_done

__mmc_init_failed:
  bl printk
  
  /* Invalidate card status */
  ldr r0, =MMC_CARD_FEATS
  mov r1, #0
  str r1, [r0, #MMC_F_CardInserted]
  
  /* Disable MCI interrupt */
  ldr r0, =AIC_BASE
  mov r1, #(1 << 9)
  str r1, [r0, #AIC_IDCR]
  
__mmc_init_done:  
  ldmfd sp!, {r0-r6,pc}

mmc_irq_handler:
  sub r14, r14, #4
  stmfd sp!, {r0-r4,lr}
  
  /* Signal end of IRQ handler */
  ldr r0, =AIC_BASE
  str r0, [r0, #AIC_EOICR]
  
  ldmfd sp!, {r0-r4,pc}^

/**
 * Returns card's status register.
 */
mmc_get_card_status:
  stmfd sp!, {r1-r4,lr}
  
  mov r0, #MMC_SEND_STATUS
  orr r0, r0, #MCI_CMDR_RSPTYP_48
  orr r0, r0, #MCI_CMDR_MAXLAT
  mov r1, #0
  bl mmc_send_command_with_polling
  
  /* Check if an error has ocurred */
  cmp r0, #0
  movne r0, #0
  subne r0, r0, #1
  bne __card_status_fail
  
  /* Grab status register */
  ldr r0, =MCI_BASE
  ldr r0, [r0, #MCI_RSPR]

__card_status_fail:
  ldmfd sp!, {r1-r4,pc}

/**
 * Performs MMC card discovery on the bus by requesting cards
 * to send contents of their CID register. Note that only the
 * first card is registred.
 *
 * @return Zero on success, non-zero on failure
 */
mmc_discover_cards:
  stmfd sp!, {r1-r8,lr}

  /* Send ALL_SEND_CID to cards */
  mov r0, #MMC_ALL_SEND_CID
  orr r0, r0, #MCI_CMDR_RSPTYP_136
  orr r0, r0, #MCI_CMDR_OPDCMD
  bl mmc_send_command_with_polling
  
  /* Check if an error has ocurred */
  cmp r0, #0
  bne __discover_fail
  
  /* If not, read CID and assign the card a relative address */
  ldr r5, =MMC_CARD_FEATS
  mov r1, #1
  str r1, [r5, #MMC_F_CardInserted]       /* Set card status to 1 */
  mov r1, #0
  str r1, [r5, #MMC_F_RelativeCardAddr]   /* Set RCA to 0x0 */
  
  /* Set relative card addr for the card */
  mov r0, #MMC_SET_RELATIVE_ADDR
  orr r0, r0, #MCI_CMDR_RSPTYP_48
  orr r0, r0, #MCI_CMDR_OPDCMD
  orr r0, r0, #MCI_CMDR_MAXLAT
  bl mmc_send_command_with_polling
  
  /* Check for errors */
  cmp r0, #0
  bne __discover_fail
  
  /* Request CSD register from the cards to get their features */
  mov r0, #MMC_SEND_CSD
  orr r0, r0, #MCI_CMDR_RSPTYP_136
  orr r0, r0, #MCI_CMDR_MAXLAT
  mov r1, #0
  bl mmc_send_command_with_polling
  
  /* Check for errors */
  cmp r0, #0
  bne __discover_fail
  
  ldr r0, =MCI_BASE
  ldr r1, [r0, #MCI_RSPR] /* Response part 1 */
  ldr r2, [r0, #MCI_RSPR] /* Response part 2 */
  ldr r3, [r0, #MCI_RSPR] /* Response part 3 */
  ldr r4, [r0, #MCI_RSPR] /* Response part 4 */
  
  /* Set max read data block length (from part 2) */
  mov r7, r2, lsr #MMC_CSD_RD_B_LEN_S
  and r7, r7, #MMC_CSD_RD_B_LEN_M
  mov r6, #1
  mov r6, r6, lsl r7
  str r6, [r5, #MMC_F_MaxReadBlockLen]
  
  /* Set max write data block length (from part 4) */
  mov r7, r4, lsr #MMC_CSD_WR_B_LEN_S
  and r7, r7, #MMC_CSD_WR_B_LEN_M
  mov r6, #1
  mov r6, r6, lsl r7
  str r6, [r5, #MMC_F_MaxWriteBlockLen]
  
  /* Set sector size (from part 3) */
  mov r7, r3, lsr #MMC_CSD_v22_SECT_SIZE_S
  and r7, r7, #MMC_CSD_v22_SECT_SIZE_M
  add r7, r7, #1
  str r7, [r5, #MMC_F_SectorSize]
  
  /* Set read partial (from part 2) */
  mov r7, r2, lsr #MMC_CSD_RD_B_PAR_S
  and r7, r7, #MMC_CSD_RD_B_PAR_M
  str r7, [r5, #MMC_F_ReadPartial]
  
  /* Set write partial (from part 4) */
  mov r7, r4, lsr #MMC_CSD_WR_B_PAR_S
  and r7, r7, #MMC_CSD_WR_B_PAR_M
  str r7, [r5, #MMC_F_WritePartial]
  
  /* Set read block misalignment (from part 2) */
  mov r7, r2, lsr #MMC_CSD_RD_B_MIS_S
  and r7, r7, #MMC_CSD_RD_B_MIS_M
  str r7, [r5, #MMC_F_ReadBlockMisalgn]
  
  /* Set write block misalignment (from part 2) */
  mov r7, r2, lsr #MMC_CSD_WR_B_MIS_S
  and r7, r7, #MMC_CSD_WR_B_MIS_M
  str r7, [r5, #MMC_F_WriteBlockMisalgn]
  
  /* Calculate memory capacity (from parts 2 & 3) */
  mov r7, r3, lsr #MMC_CSD_CSIZE_M_S
  and r7, r7, #MMC_CSD_CSIZE_M_M
  add r7, r7, #2
  mov r6, #1
  mov r6, r6, lsl r7    /* r6 contains MULT */
  
  mov r7, r2, lsr #MMC_CSD_CSIZE_H_S
  mov r8, #MMC_CSD_CSIZE_H_M_1
  orr r8, r8, #MMC_CSD_CSIZE_H_M_2
  and r7, r7, r8
  mov r7, r7, lsl #2    /* r7 contains MSB of CSIZE */
  
  mov r8, r3, lsr #MMC_CSD_CSIZE_L_S
  and r8, r8, #MMC_CSD_CSIZE_L_M
  add r8, r8, r7
  add r8, r8, #1
  mul r7, r6, r8        /* r7 contains MULT * (LSB of CSIZE + MSB of CSIZE + 1) = BLOCKNR */
  
  /* Now compute memory capacity */
  ldr r6, [r5, #MMC_F_MaxReadBlockLen]
  mul r8, r6, r7        /* r8 contains BLOCKNR * MaxReadBlockLen = Capacity */
  str r8, [r5, #MMC_F_Capacity]
  
  /* Success */
  mov r0, #0

__discover_fail:
  ldmfd sp!, {r1-r8,pc}

/**
 * Asks cards to specify operating conditions and powers up
 * those that fit.
 *
 * @return Zero on success, non-zero on failure
 */
mmc_power_up_cards:
  stmfd sp!, {r1-r3,lr}
  
  ldr r3, =MCI_BASE
  
__powerup_cards_loop:
  /* Send a proper command */
  mov r0, #MMC_SEND_OP_COND
  orr r0, r0, #MCI_CMDR_RSPTYP_48
  orr r0, r0, #MCI_CMDR_OPDCMD
  mov r1, #(0x3f << 15)           /* Set OCR, voltage range to 2.7 - 3.3V */
  bl mmc_send_command_with_polling
  
  /* Check if an error has ocurred */
  cmp r0, #0
  bne __powerup_fail
  
  /* Read response register */
  ldr r1, [r3, #MCI_RSPR]
  ands r2, r1, #(1 << 31)     /* Check power up status bit */
  beq __powerup_cards_loop    /* Loop until card signals power up completed */
  
  /* Success */
  mov r0, #0
  
__powerup_fail:
  ldmfd sp!, {r1-r3,pc}

/**
 * Waits until MCI is ready for operations.
 *
 * @param r0 Timeout
 */
mci_wait_ready:
  stmfd sp!, {r0-r2,lr}
  
  /* Loop until NOTBUSY is set */
  ldr r2, =MCI_BASE
  
__rdy_wait_loop:
  ldr r1, [r2, #MCI_SR]
  subs r0, r0, #1
  bmi __rdy_wait_end
  ands r1, r1, #(1 << 5)    /* Check NOTBUSY bit (bit 5) */
  beq __rdy_wait_loop

__rdy_wait_end:
  ldmfd sp!, {r0-r2,pc}

/**
 * A helper method for MMC PIO pin setup (selects peripheral A func).
 *
 * @param r0 Pin number
 * @param r1 PIO base
 * @param r2 Use pull-up resistor
 */
__mmc_setup_pin_A:
  stmfd sp!, {r0-r3,lr}
  
  /* Configure PIO */
  mov r3, #1
  mov r0, r3, lsl r0
  str r0, [r1, #PIO_IDR]    /* Disable interrupts */
  cmp r2, #1
  strne r0, [r1, #PIO_PUDR] /* Disable pull-up resistor */
  streq r0, [r1, #PIO_PUER] /* Enable pull-up resistor */
  str r0, [r1, #PIO_ASR]    /* Assign pin to peripheral A function */
  str r0, [r1, #PIO_PDR]    /* Disable PIO from controling the pin */
  
  ldmfd sp!, {r0-r3,pc}

/**
 * Sends a single command to a MMC card. Note that this function
 * will poll the MCI status to wait for command completion and
 * so this method should only be used in the initialization
 * phase and not for any DATA commands.
 *
 * Caller should read the response if needed.
 *
 * @param r0 Command number
 * @param r1 Argument
 * @return Zero on success, non-zero on failure
 */
mmc_send_command_with_polling:
  stmfd sp!, {r1-r3,lr}
  
  /* Send command as usual */
  bl mmc_send_command
  
  /* Command has been sent, wait for response */
  ldr r1, =MCI_BASE
  
__rsp_poll_loop:
  ldr r3, [r1, #MCI_SR]
  ands r2, r3, #1          /* Check CMDRDY bit */
  beq __rsp_poll_loop
  
  /* Check for errors */
  ands r2, r3, #MCI_ERROR_MASK
  beq __rsp_ok                  /* If no errors, we are good */
  
  /* If command is MMC_SEND_OP_COND then the CRC error flag
     is always set so we have to ignore that */
  and r0, r0, #MCI_CMDR_CMDNB_MASK
  cmp r0, #MMC_SEND_OP_COND
  beq __cmd_is_snd_op_cnd
  
  /* If we are here then we have failed */
  mov r0, #1
  b __rsp_fail
   
__cmd_is_snd_op_cnd:
  /* If not exactly CRC error then we have failed */
  cmp r2, #MCI_ERR_RCRCE
  movne r0, #1
  bne __rsp_fail
  
__rsp_ok:
  mov r0, #0

__rsp_fail:
  ldmfd sp!, {r1-r3,pc}

/**
 * Sends a single command to a MMC card.
 *
 * @param r0 Command number
 * @param r1 Argument
 */
mmc_send_command:
  stmfd sp!, {r0-r2,lr}
  
  /* Write command argument to MCI_ARGR and command to MCI_CMDR */
  ldr r2, =MCI_BASE
  str r1, [r2, #MCI_ARGR]
  str r0, [r2, #MCI_CMDR]
  
  ldmfd sp!, {r0-r2,pc}


.data
/* Error messages */
MSG_MMC_INIT_FAILED: .asciz "  > Failed! No MMC card present ?\n\r"
MSG_MMC_DISCOVER_FAILED: .asciz "  > Card discovery failed!\n\r"
MSG_MMC_POWERON: .asciz "  > Card initialized.\n\r"
MSG_MMC_DISCOVER_OK: .asciz "  > Card features discovered.\n\r"

/* Discovered card features */
.align 4
MMC_CARD_FEATS: .space MMC_CARD_FEATSIZE, 0x00
