/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group3
 */
.global dl_arfd

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/macros.s"
.include "include/at91sam9260.s"
.include "include/globals.s"

.text
.code 32
/**
 * svc_delay
 *
 * @param r0 Expiry (in number of jiffies from now)
 * @param r1 Pointer to TCB
 */
 
/**
 * Adding requirements for delay
 */ 
dl_arfd:    
  /* Load current task TCB pointer */
  LOAD_CURRENT_TCB r1
          
  ldr   r2, =DLYLIST                    /* r2 -> address of first DLY block */  
   
  mov r6, r0                                  
  bl irq_disable						            /* disable interruption */
  mov r7, r0
  mov r0, r6
          
  add   r4, r2, #72                     /* r4 -> address of last element in DLYLIST */
  ldr   r5, [r4, #D_TCB]				        /* R5 -> pointer to the TCB latest in a list */
  cmp   r5, #0							            /* check if FREE */
  bne   __dla_ovrflw				            /* OVERFLOW_ERROR */
          
__dla_next:    
  ldr   r3, [r2]                        /* value in the first place in the table */    
  cmp   r3, #0                          /* Is the list empty? */
  beq   __dla_emlst                     /* jump if empty */
          
  ldr   r3, [r2, #D_TOUT]               /* read the first delay in the list */
  cmp   r0, r3                          /* compare with the current delay */
  ble   __dla_addl                      /* if less or equal */

  /* if greater */          
  sub   r0, r0, r3                      /* substract  delay */
  add   r2, r2, #8                      /* go to next */
  b     __dla_next

  /* if less or equal */                 
__dla_addl:    
  mov   r4, r2                          /* save to temp */
  
__dla_srend:   
  add   r4, r4, #8                      /* go to next */
  ldr   r5, [r4, #D_TCB]                /* load value from r4 */
  cmp   r5, #0                          /* compare to 0 - are we finished? */
  bne   __dla_srend                     /* if we were to go at the end of the loop */
  
__dla_next2:
  ldr   r5, [r4, #-8]                   /* in the temp (R5) saves the previous TCB in the table */
  str   r5, [r4, #D_TCB]                /* store r5  in current TCB in the table */
  ldr   r5, [r4, #-4]                   /* in temp(r5) store TOUT of the previous in the table */
  sub   r4, r4, #8                      /* go one back */
  cmp   r4, r2                          /* are we on the right place to insert? */
  subeq r5, r5, r0                      /* substract it's TOUT for the value of TOUT of the one we want to insert */
  str   r5, [r4, #D_TOUT + 8]           /* store r5 in TOUT of the current in the table */
  bne   __dla_next2                     /* If not in the right place repeat */
                   
  /* if in the rigt place or the DLYLIST is empty */          
__dla_emlst: 
  str   r1, [r2, #D_TCB]                /* store TCB in the right place in DLYLIST */
  str   r0, [r2, #D_TOUT]               /* store TOUT in the right place in DLYLIST */
 
__dld_tcwait:                                   
  mov r0, r7							              /* enable interruption */
  bl irq_restore						
		  

/**
 * Deleting requirements for delay
 */
dl_drfd: 
  bl irq_disable						            /* disable interruption */
  mov r7, r0
          
  ldr   r2, =DLYLIST                    /* r2 -> address of the first DLY block */  
  add   r4, r2, #80                     /* r4 -> address out of DLYLIST */
  ldr   r1, [r2, #D_TCB]                /* r1 -> TCB of the first DLY block */
  cmp   r1, #0                          /* Is there any block in the list? */
  beq   __dld_exit                      /* jump to the end, if none in the list */
  ldr   r0, [r2, #D_TOUT]               /* r0 -> TOUT of the first DLY block */
  cmp   r0, #0                          /* Is there anything to count? */ 
  ldreq r6, [r1, #T_FLAG]               /* read the flags from TCB */
  biceq r6, r6, #TWAIT                  /* remove TWAIT flag */
  streq r6, [r1, #T_FLAG]               /* store the flags to TCB */
  beq   __dld_nocnt                     /* jump forward, if nothing to count */

  /* timer count*/          	  
  ldr r6, =TC0_BASE  
  ldr r5, =CDLYTCB
  ldr r5, [r5]
  cmp r5, #0
  beq __dld_firsts
  cmp r5, #-1
  bne __dld_tcwait
  
__dld_firsts:
  ldr r5, =CDLYTCB
  str r1, [r5]
  
  mov r0, r0, lsl #4         
  str r0, [r6, #TC_RC]  	  		  
        
  /* Mark tasks undispatchable */
__dld_mrknw:
  ldr   r6, [r1, #T_FLAG]               /* read the flags from TCB */
  orr   r6, r6, #TWAIT                  /* set TWAIT flag */
  str   r6, [r1, #T_FLAG]               /* store the flags to TCB */
  add   r2, r2, #8                      /* go to next */
  cmp   r2, r4                          /* are we out of DLYLIST? */
  beq   __dld_nocnt                     /* We are out of DLYLIST */
  ldr   r1, [r2, #D_TCB]                /* r1 -> TCB of the next DLY block */
  cmp   r1, #0                          /* compare to 0 - are we finished */
  bne   __dld_mrknw                     /* if not continue with setting */
                
  /* shift left every thing in DLYLIST */
__dld_nocnt: 
  ldr   r2, =DLYLIST                    /* r2 -> address of the first DLY block */ 
  
__dld_dia:
  add   r2, r2, #8                      /* move to next DLY block */
  cmp   r2, r4                          /* Are we out of DLYLIST? */
  beq   __dld_owf                       /* We are out of DLYLIST */
          
  ldr   r5, [r2, #D_TCB]                /* r5 -> TCB of the current DLY block */
  cmp   r5, #0                          /* is the current DLY block valid? */
  beq   __dld_wblock                    /* current DLY block is not valid */
          
  /* current DLY block is valid -> copy it to previous place in the list */
  str   r5, [r2, #-8]                   /* store r5  in the TCB of the previous DLY block */
  ldr   r5, [r2, #D_TOUT]               /* r5 -> TOUT of the current DLY bloka */
  str   r5, [r2, #-4]                   /* store r5 to TOUT of the previous DLY bloka */
  b     __dld_dia                       /* go to next */         
          
  /* We are out of DLYLIST */
__dld_owf: 
  mov   r5, #0

  /* current DLY block is not valid (0) -> write 0 in the previous */
__dld_wblock:   
  str   r5, [r2, #-8]                   /* write 0 into TCB of the previous DLY block */
  str   r5, [r2, #-4]                   /* write 0 into  TOUT of the previous DLY block */       
          
  mov r0, r7							              /* enable interruption */
  bl irq_restore
           
  b     dl_drfd                         /* repeat for  next */

  /* finished */
__dld_exit:   
  mov r0, r7							              /* enable interrupt */
  bl irq_restore
 
  /* Switch to some other task */
  SVC_RETURN_CODE #0
  b     svc_newtask
          
__dla_ovrflw:   
  mov r0, r7							              /* enable interrupt */
  bl irq_restore 

  /* Switch to some other task */
  SVC_RETURN_CODE #E_OVRFLV
  b     svc_newtask
		  
/*************************************************************************************************/
/*************************************************************************************************/
