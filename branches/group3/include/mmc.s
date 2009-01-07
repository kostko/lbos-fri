/* ================================================================
                    STUFF FROM MMC SPECIFICATION
   ================================================================
*/

/* Basic commands and read stream commands (Class 0 and 1) */
.equ MMC_GO_IDLE_STATE, 0
.equ MMC_SEND_OP_COND, 1
.equ MMC_ALL_SEND_CID, 2
.equ MMC_SET_RELATIVE_ADDR, 3
.equ MMC_SELECT_CARD, 7
.equ MMC_SEND_CSD, 9
.equ MMC_SEND_CID, 10
.equ MMC_READ_DAT_UNTIL_STOP, 11
.equ MMC_STOP_TRANSMISSION, 12
.equ MMC_SEND_STATUS, 13
.equ MMC_GO_INACTIVE_STATE, 15

/* Block oriented read commands (Class 2) */
.equ MMC_SET_BLOCKLEN, 16
.equ MMC_READ_SINGLE_BLOCK, 17
.equ MMC_READ_MULTIPLE_BLOCK, 18

/* Sequential write commands (Class 3) */
.equ MMC_WRITE_DAT_UNTIL_STOP, 20

/* Block oriented write commands (Class 4) */
.equ MMC_WRITE_BLOCK, 24
.equ MMC_WRITE_MULTIPLE_BLOCK, 25
.equ MMC_PROGRAM_CSD, 27

/* Response types */
.equ MCI_CMDR_RSPTYP_NONE, (0x0 << 6)
.equ MCI_CMDR_RSPTYP_48, (0x1 << 6)
.equ MCI_CMDR_RSPTYP_136, (0x2 << 6)

/* Transfer command */
.equ MCI_CMDR_TRCMD_NO, (0x0 << 16)
.equ MCI_CMDR_TRCMD_START, (0x1 << 16)
.equ MCI_CMDR_TRCMD_STOP, (0x2 << 16)

/* Transfer direction */
.equ MCI_CMDR_TRDIR_RD, (0x1 << 18)

/* Open drain command */
.equ MCI_CMDR_OPDCMD, (0x1 << 11)

/* Maximum latency command */
.equ MCI_CMDR_MAXLAT, (0x1 << 12)

/* Command number mask */
.equ MCI_CMDR_CMDNB_MASK, 0x3f

/* Errors */
.equ MCI_ERR_UNRE, (0x1 << 31)
.equ MCI_ERR_OVRE, (0x1 << 30)
.equ MCI_ERR_DTOE, (0x1 << 22)
.equ MCI_ERR_DCRCE, (0x1 << 21)
.equ MCI_ERR_RTOE, (0x1 << 20)
.equ MCI_ERR_RENDE, (0x1 << 19)
.equ MCI_ERR_RCRCE, (0x1 << 18)
.equ MCI_ERR_RDIRE, (0x1 << 17)
.equ MCI_ERR_RINDE, (0x1 << 16)
.equ MCI_ERROR_MASK, (MCI_ERR_UNRE | MCI_ERR_OVRE | MCI_ERR_DTOE | MCI_ERR_DCRCE | MCI_ERR_RTOE | MCI_ERR_RENDE | MCI_ERR_RCRCE | MCI_ERR_RDIRE | MCI_ERR_RINDE)

/* CSD offsets/masks */
.equ MMC_CSD_RD_B_LEN_S, 16
.equ MMC_CSD_RD_B_LEN_M, 0x0F
.equ MMC_CSD_WR_B_LEN_S, 22
.equ MMC_CSD_WR_B_LEN_M, 0x0F
.equ MMC_CSD_v22_SECT_SIZE_S, 7
.equ MMC_CSD_v22_SECT_SIZE_M, 0x7F
.equ MMC_CSD_RD_B_PAR_S, 15
.equ MMC_CSD_RD_B_PAR_M, 0x01
.equ MMC_CSD_WR_B_PAR_S, 21
.equ MMC_CSD_WR_B_PAR_M, 0x01
.equ MMC_CSD_RD_B_MIS_S, 13
.equ MMC_CSD_RD_B_MIS_M, 0x01
.equ MMC_CSD_WR_B_MIS_S, 14
.equ MMC_CSD_WR_B_MIS_M, 0x01
.equ MMC_CSD_CSIZE_M_S, 15
.equ MMC_CSD_CSIZE_M_M, 0x07
.equ MMC_CSD_CSIZE_H_S, 0
.equ MMC_CSD_CSIZE_H_M_1, 0xFF
.equ MMC_CSD_CSIZE_H_M_2, (0x03 << 8)
.equ MMC_CSD_CSIZE_L_S, 30
.equ MMC_CSD_CSIZE_L_M, 0x03

/* SR (Status Register) offsets */
.equ MMC_SR_READY, (1 << 8)

/* Error codes */
.equ E_MMC_NOT_AVAIL, 0x1
.equ E_MMC_BUSY, 0x2
.equ E_MMC_INVAL_ADDR, 0x3
.equ E_MMC_UNKNOWN, 0x4

/* Data structure for saving card features */
.equ MMC_F_CardInserted, 0x0
.equ MMC_F_CardStatus, MMC_F_CardInserted + 4
.equ MMC_F_RelativeCardAddr, MMC_F_CardStatus + 4
.equ MMC_F_MaxReadBlockLen, MMC_F_RelativeCardAddr + 4
.equ MMC_F_MaxWriteBlockLen, MMC_F_MaxReadBlockLen + 4
.equ MMC_F_ReadPartial, MMC_F_MaxWriteBlockLen + 4
.equ MMC_F_WritePartial, MMC_F_ReadPartial + 4
.equ MMC_F_EraseBlockEnbl, MMC_F_WritePartial + 4
.equ MMC_F_ReadBlockMisalgn, MMC_F_EraseBlockEnbl + 4
.equ MMC_F_WriteBlockMisalgn, MMC_F_ReadBlockMisalgn + 4
.equ MMC_F_SectorSize, MMC_F_WriteBlockMisalgn + 4
.equ MMC_F_Capacity, MMC_F_SectorSize + 4
.equ MMC_CARD_FEATSIZE, MMC_F_Capacity + 4
