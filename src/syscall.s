/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global syscall_handler
.global svc_newtask

/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/macros.s"
.include "include/at91sam9260.s"
.include "include/globals.s"

.text
.code 32
syscall_handler:
  /* System call handler/dispatcher */
  PUSH_CONTEXT
  mov r11, lr               /* Save link register before enabling preemption */
  ENABLE_IRQ
  
  /* Get syscall number from SWI instruction */
  ldr r12, [r11, #-4]       /* Load SWI instruction opcode + arg to r0 */
  bic r12, r12, #0xFF000000 /* Clear upper 8 bits */
  
  /* Check if SVC number is valid */
  cmp r12, #MAX_SVC_NUMBER
  bhs __bad_svc
  
  /* Get SVC address and jump to it */
  ldr r11, =SYSCALL_TABLE
  ldr r11, [r11, r12, lsl #2]
  bx r11
  
__bad_svc:
  /* Return E_BADSVC error code in r0 */
  SVC_RETURN_CODE #E_BADSVC
  POP_CONTEXT

/* ================================================================
                       SYSTEM CALLS GO HERE
   ================================================================
*/

svc_createf:
/* v r1 se poda ime file-a */
  ldr r10,=FS_FAT

  ldr r11,=FS_MEMORY

  mov r2,#2    /*ker je v FATu prvi slot oznacen z 2*/

__cf1fs_loop:
  ldr r3,[r10],#4
  cmp r3,#0
    
  bne __cf2fs_loop
  sub r10,r10,#4
  mov r3,#1
  str r3,[r10]
  b __cf3fs_loop
  
__cf2fs_loop:
  add r2,r2,#1
  cmp r10,r11
  bne __cf1fs_loop
      
__cf3fs_loop:
  /*SVC_MKDIR*/

svc_open:

  /*SVC_OPENF ki klice to funkcijo v r0 poda stevilko prve gruce file-a  */
  
  ldr r2,=FS_FAT
  ldr r1,=FS_OPENED    /*hranimo st. prve gruce odprtega file-a*/
  ldr r3,=FS_MEMORY
  ldr r4,=FS_WORKING
  
  str r0,[r1]     /*shranemo st. gruce v FS_OPENED*/
  str r0,[r9]     /* st. prve gruce shranimo v r9, tako da bo na voljo tudi za operacijo WRITE */

__op1fs_loop:
  mov r5,#256    /*steje navzdol od 256( 256*4B=1024 B), da se nalozi gruca*/
  
  /*ti trije ukazi racunajo: DATA=(st. gruce-2)*1024 + FS_MEMORY*/   
  sub r6,r0,#2   
  mov r6,r6, LSL #10
  add r6,r6,r3
      
__op2fs_loop:    /*nalozi iz MEMORY v WORKING trenutno gruco- 1024B */
  ldr r7,[r6],#4
  str r7,[r4],#4
  subs r5,r5,#1
  bne __op2fs_loop
  
  
  
  /*naslov stevilke od naslednje gruce: NASL. =FS_FAT + 4*(st. gruce-2)*/
  sub r0,r0,#2
  mov r0,r0, LSL #2
  add r0,r0,r2
  ldr r0,[r0]
  
  cmp r0,#1  /*st. gruce==1, pomeni konec file-a*/
  bne __op1fs_loop
  
svc_del: /*v r0 podana stevilka prve gruce v datoteki (od 2 naprej)*/

  cmp r0, #1                  /*preverimo, ce je stevilka gruce vecja od 1*/
  ble __del2fs_loop          /*ce ni, je napaka*/
  ldr r1,=FS_FAT             /*nalozimo zacetek FAT*/
  mov r2, #0                  /*0 za oznacevanje praznih gruc*/
__del1fs_loop:   
  sub r0, r0, #2              /*odstejemo 2, ker sta 0 in 1 rezervirani za oznacevanje*/
  add r3, r1, r0, LSL #2    /*izracunamo naslov gruce v FAT (FAT + stevilka gruce * 4)*/
  ldr r0, [r3]                   /*nalozimo vrednost gruce*/
  str r2, [r3]                   /*v gruco zapisemo 0 (oznacimo kot prazno gruco)*/
  cmp r0, #1                  /*preverimo, ce je zadnja gruca v datoteki*/
  bne __del1fs_loop         /*ce ni zadnja, ponovimo, sicer smo koncali*/
__del2fs_loop:     
  nop
  
svc_write:

  ldr r2,=FS_FAT
  ldr r1,=FS_OPENED     
  ldr r3,=FS_MEMORY
  ldr r4,=FS_WORKING
  
  ldr r0,[r9]    		 /* Shranimo st. prve gruce v r0 -> dobimo od druge skupine */

  
__wr1fs_loop:
  
  mov r5,#256        /* Stevec, ki bo odsteval navzdol od 256 (256*4B=1024B) */
  
  /* Izracunamo naslov prve gruce fajla, ki se nahaja v MEMORY in ga shranimo v r6:  */    
  sub r6,r0,#2              /* DATA = (st. gruce-2)*1024 + FS_MEMORY  */
  mov r6,r6, LSL #10   
  add r6,r6,r3             
     
__wr2fs_loop:    
  /* Trenutno gruco (1024B) prepisemo iz WORKING v MEMORY ... */
  ldr r7,[r4],#4             /* V r7 nalozimo vsebino na naslovu WORKING */
  str r7,[r6],#4             /* V MEMORY na naslovu DATA shranimo vsebino r7 */
  subs r5,r5,#1             /* Stevec v r5 zmanjsamo za 1 (prenesli smo 4B). */
  bne __wr2fs_loop        /* Ponavljamo dokler nismo prenesli vseh 1024B */
  
  /* V tabeli FAT poiscemo naslednjo gruco: */
  sub r0,r0,#2             
  mov r0,r0, LSL #2      
  add r0,r0,r2             
  ldr r0,[r0]                 
  
  cmp r0,#1                 /* V kolikor je st. gruce enaka 1, pomeni da je to konec fajla */
  bne __wr1fs_loop       /* Ponavljamo dokler nismo dosegli konec fajla... */
  
svc_append:

  /* Uporabnik bo V register r10 shranil stevilo novih gruc, ki jih zeli dodati */
  
  ldr r2,=FS_FAT
  ldr r10,=FS_CLUSTERS
  
  ldr r0,[r9] /* Shranimo st. prve gruce v r0 -> dobimo od druge skupine */
  ldr r8,[r10] /* V r8 shranimo st. novih gruc */
  
  
/* Prvi korak:  Pregledamo tabelo FAT in si zapomnimo naslov zadnje gruèe v datoteki...  */
__app1fs_loop:
  
  mov r4, r0 /* V r4 shranimo st. trenutne gruce */
  
  /* V tabeli FAT poiscemo naslednjo gruco: */
  sub r0,r0,#2
  mov r0,r0, LSL #2
  add r0,r0,r2
  /* V register r5 shranimo naslov, kjer bo po koncu zanke oznacen konec datoteke. Potrebovali ga bomo v koraku 2: */
  mov r5,r0
  ldr r0,[r0]
  
  cmp r0,#1 /* V kolikor je st. gruce enaka 1, pomeni da je to konec fajla */
  bne __app1fs_loop /* Ponavljamo dokler nismo dosegli konec fajla ... */
  
	mov r4, #2	/* Zaènemo na zaèetku tabele FAT */
  
/* Drugi korak: dodamo nove gruèe v tabelo */

__app2fs_loop:      

/* V tabeli FAT poišèemo naslednjo prazno gruèo: */

add r4, r4, #1	/* V r4 shranimo št. naslednje gruèe v tabeli FAT */
mov r0, r4			/* V r0 vpišemo št. naslednje gruèe*/

sub r0,r0,#2             
mov r0,r0, LSL #2      
add r0,r0,r2             
mov r6,r0				/* V r6 shranimo naslov trenutne gruèe */
ldr r0,[r0]     /* V r0 sedaj shranimo še vsebino iz naslova od r0 (št. naslednje gruèe) */

cmp r0, #0
bne __app2fs_loop      /* Èe gruèa ni prazna, poišèemo naslednjo*/

	str r4, [r5]		/* V gruèo, ki je prej oznaèevala konec vpišemo št. naslednje gruèe */
	mov r0, #1			/* Z 1 bomo oznaèili nov konec datoteke */
	str r0, [r6]		/* V prosto gruèo oznaèimo nov konec datoteke */
	mov r5, r6			/* V r5 si zapomnimo naslov novega konca datoteke */
	sub r8, r8, #1	/* Št. novih gruè zmanjšamo za 1, saj smo eno pravkar dodali */

	cmp r8,#0             	 /* Preverimo ali smo v tabelo FAT dodali že vse nove gruèe */
	bne __app2fs_loop        /* Ponavljamo dokler nismo dodali vseh novih gruè */
  
  
  /* Tretji korak: Iz delovnega pomnilnika prenesemo vse v glavni pomnilnik... */
  swi #SYS_WRITE /* Klicemo funkcijo WRITE */


svc_truncate:
  /* Uporabnik bo V register r10 shranil stevilo gruc, ki jih zeli odstraniti */
  
  ldr r2,=FS_FAT
  ldr r10,=FS_CLUSTERS
  
  ldr r0,[r9] /* Shranimo st. prve gruce v r0 -> dobimo od druge skupine */
  ldr r8,[r10] /* V r8 shranimo st. novih gruc */
  
/* Prvi korak:  Pregledamo tabelo FAT preštejemo koliko gruè že ima datoteka.  */
__trun1fs_loop:

	add r4, r4, #1					/* Števec gruè */

	/* V tabeli FAT poišèemo naslednjo gruèo: */
	sub r0,r0,#2             
	mov r0,r0, LSL #2      
	add r0,r0,r2             
	ldr r0,[r0]             /* V r0 sedaj shranimo še vsebino iz naslova od r0 (št. naslednje gruèe) */

	cmp r0,#1               /* V kolikor je št. gruèe enaka 1, pomeni da je to konec fajla */
	bne _trun1fs_loop       /* Ponavljamo dokler nismo dosegli konec fajla ... */

/* Drugi korak:  V tabeli FAT odstranimo odveène gruèe...  */

ldr r0,[r9]             /* Še enkrat bomo šli èez vse gruèe odprte datoteke ...*/
sub r4, r4, r8	   			/* Koliko gruè pustimo? -> št. vseh gruè v fajlu minus št. gruè, ki jih želi odstraniti uporabnik */
add r8, r8, #1	   			/* Št. gruè, ki je zapisano v r8 poveèamo za 1, samo zato, ker potrebujemo dodaten obhod zanke */
mov r5, #0	   					/* Pomagali si bomo še z enim števcem */
mov r3, #1	   					/* Z 1 bomo oznaèili nov konec datoteke */

_trun2fs_loop:        

add r5, r5, #1

/* V tabeli FAT poišèemo naslednjo gruèo: */
sub r0,r0,#2             
mov r0,r0, LSL #2      
add r0,r0,r2             
mov r6,r0	    					/* V r6 shranimo naslov trenutne gruèe */
ldr r0,[r0]             /* V r0 sedaj shranimo še vsebino iz naslova od r0 (št. naslednje gruèe) */

cmp r5, r4	    				/* Preverimo èe smo že šli mimo vseh gruè, ki bodo ostale v datoteki */
bne _trun2fs_loop       /* Ponavljamo, dokler nismo šli mimo vseh gruè, ki bodo ostale */
	
		str r3, [r6]				/* Oznaèimo nov konec datoteke */
		mov r3, #0					/* Vse naslednje gruèe v datoteki bomo oznaèili kot prazne... */
		add r4, r4, #1			/* Èe hoèemo, da bo pogoj izpolnjen tudi ob naslednjem obhodu, ko vpisujemo nièle, moramo poveèati tudi števec r4 */
		sub r8, r8, #1			/* Odstranili smo gruèo */
	
		cmp r8, #0          /* Preverimo, èe smo odstranili že vse gruèe. */
		bne _trun2fs_loop   /* Ponavljamo, dokler nismo odstranili vseh gruè ... */
  
  
  
  /* Tretji korak: Iz delovnega pomnilnika prenesemo vse v glavni pomnilnik... */
  swi #SYS_WRITE /* Klicemo funkcijo WRITE */

/**
 * New task syscall.
 */
svc_newtask:
  /* Load current task TCB pointer */
  LOAD_CURRENT_TCB r0
  cmp r0, #0
  beq dispatch      /* No current process, enter dispatch */
  
  /* Save current task's context. */
  DISABLE_PIT_IRQ
  GET_SP #PSR_MODE_SYS, r3    /* Get USP */
  str r3, [r0, #T_USP]        /* Store USP */
  str sp, [r0, #T_SSP]        /* Store SSP */
  
  /* Branch to scheduler */
  b dispatch

/**
 * Print line syscall.
 */
svc_println:
  /* TODO */
  b svc_println

/**
 * Delay syscall.
 *
 * @param r0 Number of jiffies to delay execution for
 */
svc_delay:
  /* Load current task TCB pointer */
  LOAD_CURRENT_TCB r1
  
  /* Register a new timer */
  bl register_timer
  
  /* Mark current task undispatchable */
  DISABLE_IRQ
  ldr r2, [r1, #T_FLAG]
  orr r2, r2, #TWAIT
  str r2, [r1, #T_FLAG]
  ENABLE_IRQ
  
  /* Switch to some other task */
  SVC_RETURN_CODE #0
  b svc_newtask

/**
 * Send message syscall.
 *
 * @param r0 Buffer address
 * @param r1 Buffer size
 * @param r2 Task number
 */
svc_send:
  /* Check if task number is valid before grabbing any MCBs,
     otherwise we would have to return them back after an
     error is detected. */
  cmp r2, #MAXTASK
  bhs __err_badtask
    

  mov r3, r0
  mov r4, r1
  mov r5, r2
  
  /* Resolve physical address for buffer address that sender put in MCB */
  bl vm_get_phyaddr 
  
  DISABLE_IRQ  
  ldr r3, =MCBLIST
  ldr r4, [r3]          /* Load first MCB base into r4 */
  cmp r4, #0            /* Check if it is not NULL */
  beq __err_nomcbs
  ldr r5, [r4, #M_LINK] /* Get next MCB in line */
  str r5, [r3]          /* Now we hold our own MCB */
  ENABLE_IRQ
  
  /* Transfer data to MCB */
  mov r3, #0
  str r3, [r4, #M_LINK]   /* Clear M_LINK of our MCB */
  str r0, [r4, #M_BUFF]   /* Put buffer address into MCB */
  str r1, [r4, #M_COUNT]  /* Put buffer length into MCB */
  
  LOAD_CURRENT_TCB r0     /* Get pointer to current task's TCB */
  str r0, [r4, #M_RTCB]   /* Save task TCB into MCB */
  
  /* Grab destination task */
  ldr r1, =TASKTAB
  ldr r1, [r1, r2, lsl #2]  /* Load destination task's TCB address */
  add r3, r1, #T_MSG        /* Calculate destination message queue address */
  
  DISABLE_IRQ
  /* Alter current task's flags so it gets eliminated from dispatch
     process */
  ldr r5, [r0, #T_FLAG]
  orr r5, r5, #MWAIT
  str r5, [r0, #T_FLAG]
  
  /* Find end of queue to insert our MCB */
__find_mcb:
  ldr r0, [r3, #M_LINK]   /* Load link to next into r0 */
  cmp r0, #0
  beq __found_mcb         /* If NULL is found, we are done */
  mov r3, r0              /* Follow the M_LINK */
  b __find_mcb

__found_mcb:
  str r4, [r3, #M_LINK]   /* Append our MCB to end of queue */
  
  /* Clear target task RWAIT flag */
  ldr r0, [r1, #T_FLAG]
  bic r0, r0, #RWAIT
  str r0, [r1, #T_FLAG]
  ENABLE_IRQ
  
  /* Switch to some other task */
  b svc_newtask
  
__err_nomcbs:
  /* Return E_NOMCB error code in r0 */
  SVC_RETURN_CODE #E_NOMCB
  POP_CONTEXT
  
__err_badtask:
  /* Return E_BADTASK error code in r0 */
  SVC_RETURN_CODE #E_BADTASK
  POP_CONTEXT

/**
 * Receive message syscall.

 * @param r0 Buffer address
 * @param r1 Buffer size
 */
svc_recv:
  cmp r0, #0x30000000	/* Check if buffer address is valid (is in process' virtual address space) */
  blo __err_badaddress  

  mov r4, r0            
  mov r5, r1

__rcv_wait:
  /* Get current task's TCB */
  LOAD_CURRENT_TCB r0
  
  DISABLE_IRQ
  ldr r1, [r0, #T_MSG]  /* MCB */
  cmp r1, #0            /* Check if there are any messages */
  beq __wait_for_msg    /* If none, wait */
  
  ldr r2, [r1, #M_LINK] /* Load first message link */
  str r2, [r0, #T_MSG]  /* Remove first message from queue */
  ldr r2, [r0, #T_RPLY] /* Load address of first MCB in reply queue */
  str r2, [r1, #M_LINK]
  str r1, [r0, #T_RPLY] /* Insert message into reply queue */
    
  ldr r2, [r1, #M_BUFF] /* Load address that sender put in MCB (svc_send translated it from virtual to physical) */
  ldr r3, [r1, #M_COUNT] /* Load buffer size that sender put in MCB */
  str r4, [r1, #M_BUFF] /* Save virtual buffer address, where receiver wants to get data */
  
  /* Compare sender's buffer size with receiver's buffer size. 
     Lower of both values is now in r5 and we store it back to MCB. */
  cmp r3,r5
  movls r5, r3  
  str r5, [r1, #M_COUNT] 
  
  add r6, r5, r0		/* Check if buffer address is valid (is in process' virtual address space) */
  cmp r6, #0xF0000000
  bhi __err_badaddress  

  mov r6, r1 /* MCB */
  
  /* Copy to receiver's data section */ 
  mov r1, r2 
  mov r0, r4
  mov r2, r5  
  bl memcpy
  
  /* Return MCB address to userspace */
  SVC_RETURN_CODE r6
  POP_CONTEXT

__wait_for_msg:
  /* Set RWAIT flag for current task */
  ldr r1, [r0, #T_FLAG]
  orr r1, r1, #RWAIT
  str r1, [r0, #T_FLAG]
  
  /* Switch to other task and retry receive */
  swi #SYS_NEWTASK
  b __rcv_wait

__err_badaddress:
  /* Return E_BADADDRESS error code in r0 */
  SVC_RETURN_CODE #E_BADADDRESS
  POP_CONTEXT

/**
 * Reply to a message syscall.
 *
 * @param r0 MCB address
 */
svc_reply:
  /* Get current task's TCB */
  LOAD_CURRENT_TCB r1
  
  /* Get list header and start MCB search to find the MCB
     directly before us */
  add r2, r1, #T_RPLY
  
  DISABLE_IRQ
__find_mcb_reply:
  ldr r3, [r2, #M_LINK]
  cmp r3, #0              /* Check if we have reached the end */
  beq __err_badmcb        /* If so, passed MCB is invalid */
  cmp r3, r0              /* Is next our MCB ? */
  beq __found_mcb_reply   /* If so, we are done */
  mov r2, r3              /* Follow the link */
  b __find_mcb_reply

__found_mcb_reply:
  /* MCB is valid, take it out (r2 = MCB before us in the list) */
  ldr r3, [r0, #M_LINK]
  str r3, [r2, #M_LINK]
  
  /* Update sender's TCB */
  ldr r3, [r0, #M_RTCB]   /* Load sender's TCB pointer to r3 */
  ldr r5, [r3, #T_FLAG]   /* Load sender's flags to r5 */
  bic r5, r5, #MWAIT      /* Clear MWAIT flag */
  str r5, [r3, #T_FLAG]   /* Store flags back */
  
  /* Put MCB back in free list */
  ldr r1, =MCBLIST
  ldr r2, [r1]
  str r2, [r0, #M_LINK]
  str r0, [r1]
  
  ENABLE_IRQ
  b svc_newtask   /* Switch to some other task */

__err_badmcb:
  /* Return E_BADMCB error code in r0 */
  SVC_RETURN_CODE #E_BADMCB
  POP_CONTEXT

/**
 * LED status switch syscall.
 *
 * @param r0 LED status (0 - off, 1 - on)
 */
svc_led:
  cmp r0, #0
  beq __led_off
  LED_ON
  b __led_done
  
__led_off:
  LED_OFF
  
__led_done:
  SVC_RETURN_CODE #0
  POP_CONTEXT

/**
 * Reads a block of data from the inserted MMC card.
 *
 * @param r0 Source address
 * @param r1 Pointer to destination buffer
 * @param r2 Number of bytes to read
 */
svc_mmc_read:
  /* Get us a free page for the IO structure */
  mov r3, r0
  bl mm_alloc_page
  
  /* Resolve physical address for our buffer */
  mov r4, r0
  mov r0, r1
  bl vm_get_phyaddr
  mov r1, r0
  mov r0, r4
  
  /* Store stuff into the IO request struct */
  mov r4, #IO_OP_READ
  str r4, [r0, #IO_RQ_OPER]
  str r3, [r0, #IO_RQ_ADDR]
  str r1, [r0, #IO_RQ_BUF]
  str r2, [r0, #IO_RQ_LEN]
  
  /* Queue our request and block current task until request
     is completed. */
  mov r4, r0                  /* Save structure address for later */
  bl io_queue_request
  ldr r3, [r4, #IO_RQ_RESULT] /* Save return code for later */
  
  /* Free memory allocated for IO request struct */
  mov r0, r4
  bl mm_free_page
  
  SVC_RETURN_CODE r3
  POP_CONTEXT

/**
 * Writes a block of data to the inserted MMC card.
 *
 * @param r0 Destination address
 * @param r1 Pointer to source buffer
 * @param r2 Number of bytes to write
 */
svc_mmc_write:
  /* Get us a free page for the IO structure */
  mov r3, r0
  bl mm_alloc_page
  
  /* Resolve physical address for our buffer */
  mov r4, r0
  mov r0, r1
  bl vm_get_phyaddr
  mov r1, r0
  mov r0, r4
  
  /* Store stuff into the IO request struct */
  mov r4, #IO_OP_WRITE
  str r4, [r0, #IO_RQ_OPER]
  str r3, [r0, #IO_RQ_ADDR]
  str r1, [r0, #IO_RQ_BUF]
  str r2, [r0, #IO_RQ_LEN]
  
  /* Queue our request and block current task until request
     is completed. */
  mov r4, r0                  /* Save structure address for later */
  bl io_queue_request
  ldr r3, [r4, #IO_RQ_RESULT] /* Save return code for later */
  
  /* Free memory allocated for IO request struct */
  mov r0, r4
  bl mm_free_page
  
  SVC_RETURN_CODE r3
  POP_CONTEXT

/**
 * Terminates the current task.
 */
svc_exit:
  /* Get current task's TCB */
  LOAD_CURRENT_TCB r1
  
  /* Overwrite task's flags */
  mov r0, #TFINISHED
  str r0, [r1, #T_FLAG]
  
  /* This task is finished, let's go somewhere else */
  b svc_newtask
  
  

/* ================================================================
                           SYCALL TABLE
   ================================================================
*/
.data
.align 2
SYSCALL_TABLE:
.long svc_newtask   /* (0) enter dispatcher */
.long svc_println   /* (1) print line to serial console */
.long svc_delay     /* (2) delay */
.long svc_send      /* (3) send message */
.long svc_recv      /* (4) receive message */
.long svc_reply     /* (5) reply to a message */
.long svc_led       /* (6) LED manipulation syscall */
.long svc_mmc_read  /* (7) MMC block read */
.long svc_mmc_write /* (8) MMC block write */
.long svc_exit      /* (9) exit current task */
.long svc_createf   /* (10) create file */
.long svc_open      /* (11) open file */
.long svc_del       /* (12) delete data */
.long svc_write     /* (13) write data */
.long svc_append    /* (14) append data */
.long svc_truncate  /* (15) truncate file */

END_SYSCALL_TABLE:
.equ MAX_SVC_NUMBER, (END_SYSCALL_TABLE-SYSCALL_TABLE)/4
