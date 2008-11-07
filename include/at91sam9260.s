.equ PMC_PCER, 0xFFFFFC10 /* (PMC) Peripheral Clock Enable Register */
.equ CKGR_PLLAR, 	0xFFFFFC28 /* (CKGR) PLL A Register */
.equ CKGR_MOR,	0xFFFFFC20 /* (CKGR) Main Oscillator Register */
.equ PMC_SR,	0xFFFFFC68 /* (PMC) Status Register */
.equ PMC_MCKR,	0xFFFFFC30 /* (PMC) Master Clock Register */

.equ PIOC_BASE, 0xFFFFF800
.equ PIO_PER, 0x00
.equ PIO_OER, 0x10
.equ PIO_SODR, 0x30
.equ PIO_CODR, 0x34

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

.equ AIC_BASE, 	0xFFFFF000 	/* Zacetek AIC */
.equ AIC_SMR17, 	0x044 		/* odmiki */
.equ AIC_SVR17, 	0x0C4
.equ AIC_SMR1,  0x04
.equ AIC_SVR1,  0x84
.equ AIC_IVR, 	0x100
.equ AIC_IECR, 	0x120
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

.equ DBGU_RPR, 0x100 /* (DBGU) Receive Pointer Register */
.equ DBGU_RCR, 0x104 /* (DBGU) Receive Counter Register */
.equ DBGU_TPR, 0x108 /* (DBGU) Transmit Pointer Register */
.equ DBGU_TCR, 0x10C /* (DBGU) Transmit Counter Register */
.equ DBGU_RNPR, 0x110 /* (DBGU) Receive Next Pointer Register */
.equ DBGU_RNCR, 0x114 /* (DBGU) Receive Next Counter Register */
.equ DBGU_TNPR, 0x118 /* (DBGU) Transmit Next Pointer Register */
.equ DBGU_TNCR, 0x11C /* (DBGU) Transmit Next Counter Register */
.equ DBGU_PTCR, 0x120 /* (DBGU) Periph. Transfer Control Register */
.equ DBGU_PTSR, 0x124 /* (DBGU) Periph. Transfer Status Register */

.equ PIT_BASE, 0xFFFFFD40 /* PIT Base address */
.equ PIT_MR, 0x00    /* PIT Mode Register */
.equ PIT_SR, 0x04    /* PIT Status Register */
.equ PIT_PIVR, 0x08  /* PIT Periodic Interval Value Register */
.equ PIT_PIIR, 0x0C  /* PIT Periodic Interval  Image Register */
.equ PIT_MODE, 0x030FFFFF /* PITEN = 1, PITIEN = 1, PIV = FFFFF */

.equ PSR_MODE_MASK, 0x1F /* Mode mask */
.equ PSR_MODE_USER, 0x10 /* User mode */
.equ PSR_MODE_FIQ, 0x11  /* FIQ mode */
.equ PSR_MODE_IRQ, 0x12  /* IRQ mode */
.equ PSR_MODE_SVC, 0x13  /* SVC mode */
.equ PSR_MODE_ABT, 0x17  /* Abort mode */
.equ PSR_MODE_UND, 0x1B  /* Undef mode */
.equ PSR_MODE_SYS, 0x1F  /* System mode */
