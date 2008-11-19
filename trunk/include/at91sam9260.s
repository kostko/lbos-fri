.equ PMC_PCER, 0xFFFFFC10 /* (PMC) Peripheral Clock Enable Register */
.equ CKGR_PLLAR, 	0xFFFFFC28 /* (CKGR) PLL A Register */
.equ CKGR_MOR,	0xFFFFFC20 /* (CKGR) Main Oscillator Register */
.equ PMC_SR,	0xFFFFFC68 /* (PMC) Status Register */
.equ PMC_MCKR,	0xFFFFFC30 /* (PMC) Master Clock Register */

.equ PIOA_BASE, 0xFFFFF400
.equ PIOB_BASE, 0xFFFFF600
.equ PIOC_BASE, 0xFFFFF800
.equ PIO_PER, 0x00
.equ PIO_PDR, 0x04
.equ PIO_OER, 0x10
.equ PIO_SODR, 0x30
.equ PIO_CODR, 0x34
.equ PIO_IER, 0x40
.equ PIO_IDR, 0x44
.equ PIO_PUDR, 0x60
.equ PIO_PUER, 0x64
.equ PIO_ASR, 0x70
.equ PIO_BSR, 0x74

.equ TC0_BASE, 0xFFFA0000	/* TC0 Channel Registers */
.equ TC_IMR, 0x02C	/* TC0 Interrupt Mask Register */
.equ TC_IER, 0x24	  /* TC0 Interrupt Enable Register*/
.equ TC_RC, 0x1C		/* TC0 Register C */
.equ TC_RA, 0x14		/* TC0 Register A */
.equ TC_CMR, 0x04	  /* TC0 Channel Mode Register (Capture Mode / Waveform Mode */
.equ TC_IDR, 0x28	  /* TC0 Interrupt Disable Register */
.equ TC_SR, 0x20		/* TC0 Status Register */
.equ TC_RB, 0x18		/* TC0 Register B */
.equ TC_CV, 0x10		/* TC0 Counter Value */
.equ TC_CCR, 0x00	  /* TC0 Channel Control Register */

.equ AIC_BASE, 	0xFFFFF000
.equ AIC_SMR17, 	0x44
.equ AIC_SVR17, 	0xC4
.equ AIC_SMR1,  0x04
.equ AIC_SVR1,  0x84
.equ AIC_SMR9,  0x24
.equ AIC_SVR9,  0xA4
.equ AIC_IVR, 	0x100
.equ AIC_IECR, 	0x120
.equ AIC_IDCR, 0x124
.equ AIC_ICCR, 0x128
.equ AIC_EOICR, 	0x130

.equ PMC_BASE, 0xFFFFFC00
.equ PMC_PCER, 0x0010
.equ PMC_PCDR, 0x0014
.equ PMC_PCSR, 0x0018

.equ DBGU_BASE, 0xFFFFF200 /* (DBGU) Base address */
.equ DBGU_EXID, 0x44 /* (DBGU) Chip ID Extension Register */
.equ DBGU_THR, 0x1C /* (DBGU) Transmitter Holding Register*/
.equ DBGU_SR, 0x14 /* (DBGU) Status Register */
.equ DBGU_IDR, 0x0C /* (DBGU) Interrupt Disable Register */
.equ DBGU_MR, 0x04 /* (DBGU) Mode Register */
.equ DBGU_FNTR, 0x48 /* (DBGU) Force NTRST Register */
.equ DBGU_CIDR, 0x40 /* (DBGU) Chip ID Register */
.equ DBGU_BRGR, 0x20 /* (DBGU) Baud Rate Generator Register*/
.equ DBGU_RHR, 0x18 /* (DBGU) Receiver Holding Register */
.equ DBGU_IMR, 0x10 /* (DBGU) Interrupt Mask Register */
.equ DBGU_IER, 0x08 /* (DBGU) Interrupt Enable Register */
.equ DBGU_CR, 0x00 /* (DBGU) Control Register */

.equ PDC_RPR, 0x100 /* (PDC) Receive Pointer Register */
.equ PDC_RCR, 0x104 /* (PDC) Receive Counter Register */
.equ PDC_TPR, 0x108 /* (PDC) Transmit Pointer Register */
.equ PDC_TCR, 0x10C /* (PDC) Transmit Counter Register */
.equ PDC_RNPR, 0x110 /* (PDC) Receive Next Pointer Register */
.equ PDC_RNCR, 0x114 /* (PDC) Receive Next Counter Register */
.equ PDC_TNPR, 0x118 /* (PDC) Transmit Next Pointer Register */
.equ PDC_TNCR, 0x11C /* (PDC) Transmit Next Counter Register */
.equ PDC_PTCR, 0x120 /* (PDC) Periph. Transfer Control Register */
.equ PDC_PTSR, 0x124 /* (PDC) Periph. Transfer Status Register */

.equ PIT_BASE, 0xFFFFFD30 /* PIT Base address */
.equ PIT_MR, 0x00    /* PIT Mode Register */
.equ PIT_SR, 0x04    /* PIT Status Register */
.equ PIT_PIVR, 0x08  /* PIT Periodic Interval Value Register */
.equ PIT_PIIR, 0x0C  /* PIT Periodic Interval  Image Register */
.equ PIT_MODE, 0x030FFFFF /* PITEN = 1, PITIEN = 1, PIV = FFFFF */

.equ MCI_BASE, 0xFFFA8000
.equ MCI_CR, 0x00
.equ MCI_MR, 0x04
.equ MCI_DTOR, 0x08
.equ MCI_SDCR, 0x0C
.equ MCI_ARGR, 0x10
.equ MCI_CMDR, 0x14
.equ MCI_BLKR, 0x18
.equ MCI_RSPR, 0x20
.equ MCI_SR, 0x40
.equ MCI_IER, 0x44
.equ MCI_IDR, 0x48

.equ PSR_MODE_MASK, 0x1F /* Mode mask */
.equ PSR_MODE_USER, 0x10 /* User mode */
.equ PSR_MODE_FIQ, 0x11  /* FIQ mode */
.equ PSR_MODE_IRQ, 0x12  /* IRQ mode */
.equ PSR_MODE_SVC, 0x13  /* SVC mode */
.equ PSR_MODE_ABT, 0x17  /* Abort mode */
.equ PSR_MODE_UND, 0x1B  /* Undef mode */
.equ PSR_MODE_SYS, 0x1F  /* System mode */
