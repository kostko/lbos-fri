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
          
  ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */  
   
  mov r6, r0                                  
  bl irq_disable						/* onemogocimo prekinitve */
  mov r7, r0
  mov r0, r6
          
  add   r4, r2, #72                     /* r4 -> naslov na zadnjega v DLYLIST */
  ldr   r5, [r4, #D_TCB]				/* r5 -> kazalec na TCB zadnjega v vrsti */
  cmp   r5, #0							/* ali je mesto zasedeno? */
  bne   __dla_ovrflw				    /* mesto je zasedeno -> NAPAKA */
          
__dla_next:    
  ldr   r3, [r2]                        /* vrednost na prvem mestu v tabeli */    
  cmp   r3, #0                          /* ali je kaksen blok ze v seznamu? */
  beq   __dla_emlst                     /* skoci naprej, ce ni nobenega */
          
  ldr   r3, [r2, #D_TOUT]               /* preberi delay prvega v seznamu */
  cmp   r0, r3                          /* primerjas s trenutnim delay-em */
  ble   __dla_addl                      /* ce je manjse ali enako */

  /* ce je vecji */          
  sub   r0, r0, r3                      /* odstejes svoj delay */
  add   r2, r2, #8                      /* gres na naslednjega */
  b     __dla_next

  /* ce je manjse ali enako */                 
__dla_addl:    
  mov   r4, r2                          /* v pomozno shrani */
  
__dla_srend:   
  add   r4, r4, #8                      /* hodi naprej */
  ldr   r5, [r4, #D_TCB]                /* nalozi vrednost z naslova r4 */
  cmp   r5, #0                          /* primerjaj z 0 - a si prsu do konca */
  bne   __dla_srend                     /* ce nismo se na koncu gremo v zanko */
  
__dla_next2:
  ldr   r5, [r4, #-8]                   /* v pomoznega (r5) shrani TCB predhodnega v tabeli */
  str   r5, [r4, #D_TCB]                /* shrani r5 v TCB trenutnega v tabeli */
  ldr   r5, [r4, #-4]                   /* v pomoznega (r5) shrani TOUT predhodnega v tabeli */
  sub   r4, r4, #8                      /* gres za enga nazaj */
  cmp   r4, r2                          /* ali smo ze na pravem mestu za vstavljanje? */
  subeq r5, r5, r0                      /* odstej mu njegov TOUT za TOUT tega, ko hoces dodati */
  str   r5, [r4, #D_TOUT + 8]           /* shrani r5 v TOUT trenutnega v tabeli */
  bne   __dla_next2                     /* ce se nismo na pravem mestu ponavljamo */
                   
  /* ce smo ze na pravem mestu ali pa je DLYLIST prazen */          
__dla_emlst: 
  str   r1, [r2, #D_TCB]                /* shrani TCB na pravo mesto v DLYLIST */
  str   r0, [r2, #D_TOUT]               /* shrani TOUT na pravo mesto v DLYLIST */
 
__dld_tcwait:                                   
  mov r0, r7							/* omogocimo prekinitve */
  bl irq_restore						
		  

/**
 * Deleting requirements for delay
 */
dl_drfd: 
  bl irq_disable						/* onemogocimo prekinitve */
  mov r7, r0
          
  ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */  
  add   r4, r2, #80                     /* r4 -> naslov izven DLYLIST */
  ldr   r1, [r2, #D_TCB]                /* r1 -> TCB prvega DLY bloka */
  cmp   r1, #0                          /* ali je kaksen blok v seznamu? */
  beq   __dld_exit                      /* skoci na konec, ce ni nobenega */
  ldr   r0, [r2, #D_TOUT]               /* r0 -> TOUT prvega DLY bloka */
  cmp   r0, #0                          /* ali je kaj za steti? */ 
  ldreq r6, [r1, #T_FLAG]               /* preberi vrstico z zastavicami iz TCB-ja */
  biceq r6, r6, #TWAIT                  /* izbrisi TWAIT zastavico */
  streq r6, [r1, #T_FLAG]               /* shrani vrstico z zastavicami v TCB */
  beq   __dld_nocnt                     /* skoci naprej, ce ni treba stetja */

  /* timer steje */          	  
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
  ldr   r6, [r1, #T_FLAG]               /* preberi vrstico z zastavicami iz TCB-ja */
  orr   r6, r6, #TWAIT                  /* postavi TWAIT zastavico */
  str   r6, [r1, #T_FLAG]               /* shrani vrstico z zastavicami v TCB */
  add   r2, r2, #8                      /* hodi naprej */
  cmp   r2, r4                          /* ali smo ze izven DLYLIST-a? */
  beq   __dld_nocnt                     /* smo izven DLYLIST-a */
  ldr   r1, [r2, #D_TCB]                /* r1 -> TCB naslednjega DLY bloka */
  cmp   r1, #0                          /* primerjaj z 0 - a si prsu do konca */
  bne   __dld_mrknw                     /* ce se nisi na koncu nadaljuj z postavljanjem */
                
  /* premeci vse v DLYLIST-u za ena v levo (nazaj) */
__dld_nocnt: 
  ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */ 
  
__dld_dia:
  add   r2, r2, #8                      /* pomakni se na naslednji DLY blok */
  cmp   r2, r4                          /* ali smo ze izven DLYLIST-a? */
  beq   __dld_owf                       /* smo izven DLYLIST-a */
          
  ldr   r5, [r2, #D_TCB]                /* r5 -> TCB trenutnega DLY bloka */
  cmp   r5, #0                          /* ali je veljaven trenutni DLY blok? */
  beq   __dld_wblock                    /* trenutni DLY blok ni veljaven */
          
  /* trenutni DLY blok je veljaven -> kopiraj ga za eno nazaj */
  str   r5, [r2, #-8]                   /* r5 shrani v TCB prejsnega DLY bloka */
  ldr   r5, [r2, #D_TOUT]               /* r5 -> TOUT trenutnega DLY bloka */
  str   r5, [r2, #-4]                   /* r5 shrani v TOUT prejsnega DLY bloka */
  b     __dld_dia                       /* pojdi naprej */         
          
  /* smo izven DLYLIST-a */
__dld_owf: 
  mov   r5, #0

  /* trenutni DLY blok ni veljaven (0) -> zapisi 0 tudi v prejsnega */
__dld_wblock:   
  str   r5, [r2, #-8]                   /* zapisi 0 v TCB prejsnega DLY bloka */
  str   r5, [r2, #-4]                   /* zapisi 0 v TOUT prejsnega DLY bloka */        
          
  mov r0, r7							/* omogocimo prekinitve */
  bl irq_restore
           
  b     dl_drfd                         /* ponovi za naslednjega */

  /* koncano */
__dld_exit:   
  mov r0, r7							/* omogocimo prekinitve */
  bl irq_restore
 
  /* Switch to some other task */
  SVC_RETURN_CODE #0
  b     svc_newtask
          
__dla_ovrflw:   
  mov r0, r7							/* omogocimo prekinitve */
  bl irq_restore 

  /* Switch to some other task */
  SVC_RETURN_CODE #E_OVRFLV
  b     svc_newtask
		  
/*************************************************************************************************/
/*************************************************************************************************/
