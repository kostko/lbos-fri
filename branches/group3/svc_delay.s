/*************************************************************************************************/
/*                                                                                               */
/*                                         SVC_DELAY                                             */
/*        r0 : stevilo urinih period zakasnitve                                                  */
/*        r1 : TCB trenutnega procesa (current)                                                  */
/*                                                                                               */
/*************************************************************************************************/

DELAY:    /* Load current task TCB pointer */
          LOAD_CURRENT_TCB r1
          
          ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */  
          
          DISABLE_IRQ                           /* onemogocimo prekinitve */
          
          add   r4, r2, #72                     /* r4 -> naslov na zadnjega v DLYLIST */
          ldr   r5, [r4, #D_TCB]		/* r5 -> kazalec na TCB zadnjega v vrsti */
          cmp   r5, #0        			/* ali je mesto zasedeno? */
          bne   NAPAKA				/* mesto je zasedeno -> NAPAKA */
          
NAZAJ:    ldr   r3, [r2]                        /* vrednost na prvem mestu v tabeli */    
          cmp   r3, #0                          /* ali je kaksen blok ze v seznamu? */
          beq   PRAZLIST                        /* skoci naprej, ce ni nobenega */
          
          ldr   r3, [r2, #D_TOUT]               /* preberi delay prvega v seznamu */
          cmp   r0, r3                          /* primerjas s trenutnim delay-em */
          ble   ADD_L                           /* ce je manjse ali enako */

/* ce je vecji */          
          sub   r0, r0, r3                      /* odstejes svoj delay */
          add   r2, r2, #8                      /* gres na naslednjega */
          b     NAZAJ

/* ce je manjse ali enako */                 
ADD_L:    mov   r4, r2                          /* v pomozno shrani */
SRCEND:   add   r4, r4, #8                      /* hodi naprej */
          ldr   r5, [r4, #D_TCB]                /* nalozi vrednost z naslova r4 */
          cmp   r5, #0                          /* primerjaj z 0 - a si prsu do konca */
          bne   SRCEND                          /* ce nismo se na koncu gremo v zanko */
PREMIK:   ldr   r5, [r4, #-8]                   /* v pomoznega (r5) shrani TCB predhodnega v tabeli */
          str   r5, [r4, #D_TCB]                /* shrani r5 v TCB trenutnega v tabeli */
          ldr   r5, [r4, #-4]                   /* v pomoznega (r5) shrani TOUT predhodnega v tabeli */
          sub   r4, r4, #8                      /* gres za enga nazaj */
          cmp   r4, r2                          /* ali smo ze na pravem mestu za vstavljanje? */
          subeq r5, r5, r0                      /* odstej mu njegov TOUT za TOUT tega, ko hoces dodati */
          str   r5, [r4, #D_TOUT + 8]           /* shrani r5 v TOUT trenutnega v tabeli */
          bne   PREMIK                          /* ce se nismo na pravem mestu ponavljamo */
          
          
/* ce smo ze na pravem mestu ali pa je DLYLIST prazen */          
PRAZLIST: str   r1, [r2, #D_TCB]                /* shrani TCB na pravo mesto v DLYLIST */
          str   r0, [r2, #D_TOUT]               /* shrani TOUT na pravo mesto v DLYLIST */
          
          ENABLE_IRQ                            /* omogocimo prekinitve */                

/* zacetek stetja */
UREJENO:  DISABLE_IRQ                           /* onemogocimo prekinitve */
          
          ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */  
          add   r4, r2, #80                     /* r4 -> naslov izven DLYLIST */
          ldr   r1, [r2, #D_TCB]                /* r1 -> TCB prvega DLY bloka */
          cmp   r1, #0                          /* ali je kaksen blok v seznamu? */
          beq   KONEC                           /* skoci na konec, ce ni nobenega */
          ldr   r0, [r2, #D_TOUT]               /* r0 -> TOUT prvega DLY bloka */
          cmp   r0, #0                          /* ali je kaj za steti? */ 
          ldreq r6, [r1, #T_FLAG]               /* preberi vrstico z zastavicami iz TCB-ja */
          biceq r6, r6, #TWAIT                  /* izbrisi TWAIT zastavico */
          streq r6, [r1, #T_FLAG]               /* shrani vrstico z zastavicami v TCB */
          beq   NISTETJA                        /* skoci naprej, ce ni treba stetja */

/* timer steje */          
          /* Register a new timer */
          bl    register_timer
        
/* vsem procesom, ki so v vrsti postavi TWAIT zastavico */  
          /* Mark tasks undispatchable */
POSTNOV:  ldr   r6, [r1, #T_FLAG]               /* preberi vrstico z zastavicami iz TCB-ja */
          orr   r6, r6, #TWAIT                  /* postavi TWAIT zastavico */
          str   r6, [r1, #T_FLAG]               /* shrani vrstico z zastavicami v TCB */
          add   r2, r2, #8                      /* hodi naprej */
          cmp   r2, r4                          /* ali smo ze izven DLYLIST-a? */
          beq   NISTETJA                        /* smo izven DLYLIST-a */
          ldr   r1, [r2, #D_TCB]                /* r1 -> TCB naslednjega DLY bloka */
          cmp   r1, #0                          /* primerjaj z 0 - a si prsu do konca */
          bne   POSTNOV                         /* ce se nisi na koncu nadaljuj z postavljanjem */
         
/* stetje koncano */          
/* premeci vse v DLYLIST-u za ena v levo (nazaj) */
NISTETJA: ldr   r2, =DLYLIST                    /* r2 -> naslov prvega DLY bloka */ 
PONOVI:   add   r2, r2, #8                      /* pomakni se na naslednji DLY blok */
          cmp   r2, r4                          /* ali smo ze izven DLYLIST-a? */
          beq   IZVENDLY                        /* smo izven DLYLIST-a */
          
          ldr   r5, [r2, #D_TCB]                /* r5 -> TCB trenutnega DLY bloka */
          cmp   r5, #0                          /* ali je veljaven trenutni DLY blok? */
          beq   NIVELJ                          /* trenutni DLY blok ni veljaven */
          
/* trenutni DLY blok je veljaven -> kopiraj ga za eno nazaj */
          str   r5, [r2, #-8]                   /* r5 shrani v TCB prejsnega DLY bloka */
          ldr   r5, [r2, #D_TOUT]               /* r5 -> TOUT trenutnega DLY bloka */
          str   r5, [r2, #-4]                   /* r5 shrani v TOUT prejsnega DLY bloka */
          b     PONOVI                          /* pojdi naprej */         
          
/* smo izven DLYLIST-a */
IZVENDLY: mov   r5, #0

/* trenutni DLY blok ni veljaven (0) -> zapisi 0 tudi v prejsnega */
NIVELJ:   str   r5, [r2, #-8]                   /* zapisi 0 v TCB prejsnega DLY bloka */
          str   r5, [r2, #-4]                   /* zapisi 0 v TOUT prejsnega DLY bloka */        
          
          ENABLE_IRQ                            /* omogocimo prekinitve */
           
          b     UREJENO                         /* ponovi za naslednjega */

/* koncano */
KONEC:    ENABLE_IRQ                            /* omogocimo prekinitve */
 
          /* Switch to some other task */
          SVC_RETURN_CODE #0
          b     svc_newtask
          
NAPAKA:   ENABLE_IRQ                            /* omogocimo prekinitve */  

          /* Switch to some other task */
          SVC_RETURN_CODE #E_OVRFLV
          b     svc_newtask
		  
/*************************************************************************************************/
/*************************************************************************************************/