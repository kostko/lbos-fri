/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"


.text
.code 32
SVC_MKDIR:
	/* v R1 je podano ime imenika 
	disable interrupts
	pogledamo DIRLIST, ki kaze na prvi prazen dir, èe ga ne -> (error),
	èe ga vsebuje, potem ta kazalec shranimo v register R2, DIRLIST pa posodobimo na (*dirlist) //na kocu bo to nekaj èudnega
	enable interrupts
	
	Gremo do prvega njegovega prostega sina s katerega pokazemo na novo ustvarjeni imenik (R2). Nastavimo D_PARENT na CURRENT_DIR (ce ni nobenega 	praznega vzamemo z DIRLIST nov prostor, katerega uporabimo za hranjenje kazalcev na nove potomce), ki je shranjen v glavi
	glavi trenutnega procesa. Nastavimo D_TYPE na 0; in postavimo C_CHILD_T tudi na 0, kar pomeni da nima nobenega podimenika ali vsebovane datoteke. 
	postavimo D_NAME = R1. 
	
	*/
	ldr r3, =DIRLIST
	ldr r2, [r3]			/* naslov praznega DIR */
	cmp r2, #0			/* preverimo ce je naslov enak 0 - smo na koncu*/
	bne OK				/* ERROR  */
NO_DIR:	ldr r0, =E_NO_DIR
		b KONEC
	
OK:	ldr r4, [r2]
	str r4, [r3]			/* RLIST pa posodobimo na naslednji prazen dir */

	ldr r10, =CURRENT		/*current od trenutnega procesa*/ 
	ldr r10, [r10, #T_CURDIR]  	/*naslov trenutnega direktorija*/
	str r10, [r2, #D_PARENT]	/* praznemu direktoriju nastavimo pointer na oceta */
	str r1, [r2, #D_NAME]		/* nastavimo ime novoustvarjenemu direktoriju */
	mov r4, #0
	str r4, [r2, #D_TYPE]		/* nastavimo da je to imenik */
	str r4, [r2, #D_CHILD_T]   	/* nastavimo da je imenik prazen */

	ldr r5, [r10, #D_CHILD_T]		/* naslov current tabele otrok*/
	cmp r5, #0
	beq	NAREDI_TABELO
	
PONOVI:	ldr r7, [r5], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0			/* ce je otrok prazen, ga zapisemo */
	beq ZAPISEMO
	ldr r7, [r5], #4		/* drugace se premaknemo na naslednje mesto v tabeli */
	cmp r7, #0
	beq ZAPISEMO
	ldr r7, [r5], #4
	cmp r7, #0
	beq ZAPISEMO
	ldr r7, [r5], #4
	cmp r7, #0
	beq NAREDI_TABELO
	ldr r5, [r7]
	b PONOVI
	
ZAPISEMO:				/* v r5 imamo naslov praznega mesta */
	str r2, [r5]			/* shranimo novonarejeni imenik na to mesto */
	mov r0, #0
	b KONEC


NAREDI_TABELO:
	ldr r6, [r3]			/* naslov prazne tabele */
	cmp r6, #0			/* preverimo ce je naslov enak 0 - smo na koncu*/
	beq NO_DIR			/* ERROR  */
	ldr r4, [r6]			/* popravimo dirlist */
	str r4, [r3]

	str r6, [r5]			/* nastavimo child_table na novo tabelo, ki je v r6 */
	str r2, [r6]			/* shranimo novonarejeni imenik na prvega v tabeli */

	mov r0, #0
	b KONEC

	

	
	
SVC_REMDIR:
	/*
	V registru R1 imamo podano ime direktorija, ki ga zelimo zbrisati in smo v current direktoriju. 
	-najdemo zadnjega (je pravi?)
	-najdemo pravega, èe ima sinove -> ERR
	-pravega nastavimo na niè, damo v dirlist
	-zadnjega natavimo na mesto, kjer je bil "pravi"
	-èe je bil zadnji prvi v tabeli, pobrišemo tabelo in nastavimo child_table_p na niè
	*/

	
	ldr r10, =CURRENT		/*current od trenutnega procesa*/ 
	ldr r10, [r10, #T_CURDIR]  	/*naslov trenutnega direktorija*/
	ldr r5, [r10, #D_CHILD_T]		/* naslov current tabele otrok*/
	ldr r8, [r10, #D_CHILD_T]		/* zapomnimo si zadnji obhod -> ce brisemo tudi tabelo, je potrebno zbrisati tudi kaalec prejsnje tabele */
	cmp r5, #0
	beq	NO_CHILD_ERR
	
PONOVI2:
	ldr r7, [r5], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	ldr r7, [r7, #D_NAME]
	cmp r7, r1
	beq NAJDEN
	ldr r7, [r5], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	DIR_NOT_EXIST					/* tega imenika sploh ni */
	ldr r7, [r7, #D_NAME]
	cmp r7, r1
	beq NAJDEN
	ldr r7, [r5], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	DIR_NOT_EXIST					/* tega imenika sploh ni */
	ldr r7, [r7, #D_NAME]
	cmp r7, r1
	beq NAJDEN
	ldr r7, [r5]			/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	DIR_NOT_EXIST					/* tega imenika sploh ni */
	ldr	r5, [r7]
	b	PONOVI2	
	
	
NAJDEN:					/* nasli smo svojega za brisanje */
	sub r5, r5, #4		/* v r5 je za 4 prevelik naslov direktorija, ki ga zelimo brisati */
	ldr r6, [r5, #D_CHILD_T]
	cmp r6, #0			/* ali ima sinove */
	bne	CHILD_EXIST_ERR
BRISI_VSE:
	sub r11,r11,r11					/* v r11 shranimo nièlo */
	str r11, [r5, #D_NAME]			/* brisemo ime */
	str r11, [r5, #D_TYPE]		/* brisemo tip */
	str r11, [r5, #D_PARENT]		/* brisemo fotra */
	str r11, [r5, #D_CHILD_T]		/* brisemo otroke */
	
BACK_TO_DIRLIST:
	ldr r3, =DIRLIST
	str r3, [r5]			/* nastavimo pointer izbrisanega dira na naslednjega praznega !!!!!!!!!!!!!!!!!! ->	ERROR???*/
	str r5, [r3]			/* popravimo DIRLIST, da kaze na r5 - praznega */
	
	ldr r6, [r10, #D_CHILD_T]		/* naslov current tabele otrok*/
	cmp r6, #0
	beq	NO_CHILD_ERR

PONOVI3:					/* iscemo zadnjega, da ga prestavimo na mesto zbrisanega */
	ldr r7, [r6], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	ZADNJI_X
	ldr r7, [r6], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	ZADNJI	
	ldr r7, [r6], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	ZADNJI
	ldr r7, [r6], #4		/* zacnemo iskanje po tabeli otrok, r5 avtomatsko povecamo na naslednje mesto */
	cmp r7, #0
	beq	ZADNJI
	ldr r6, [r7]
	ldr r8, [r7]			/* zapomnimo si zadnji obhod -> ce brisemo tudi tabelo, je potrebno zbrisati tudi kaalec prejsnje tabele */ 
	b	PONOVI3
	
ZADNJI_X:					/* prestavljanje zadnjega, ce je le ta edini v tabeli -> potrebno je brisanje tabele */
	sub r6, r6, #8			/* v r6 imamo naslov zadnjega */
	str r6, [r5]
	sub r11,r11,r11					/* v r11 shranimo nièlo */
	str r11, [r6]			/* zbrisemo mesto v tabeli, kjer se je nahajal zadnji */
	
	sub r11,r11,r11					/* v r11 shranimo nièlo */
	str r11, [r6, #C_CHILD1]			/* brisemo tabelo */
	str r11, [r6, #C_CHILD2]	
	str r11, [r6, #C_CHILD3]	
	str r11, [r6, #C_CHILD_T]
	
	ldr r3, =DIRLIST		/* tabelo vrnemo v DIRLIST */ 
	ldr r4, =DIRLIST
	str r3, [r6]			/* nastavimo pointer izbrisanega dira na naslednjega praznega !!!!!!!!!!!!!!!!!! ->	ERROR???*/
	str r6, [r3]			/* popravimo DIRLIST, da kaze na r6 - praznega */
	
	str r11, [r8]			/* brisanje kazalca na naslednjo tabelo */
	b	KONEC
	

ZADNJI:						/* prestavljanje zadnjega, ce ni edini v tabeli */
	sub r6, r6, #8			/* v r6 imamo naslov zadnjega */
	str r6, [r5]
	
	sub r11,r11,r11					/* v r11 shranimo nièlo */
	str r11, [r6]			/* zbrisemo mesto v tabeli, kjer se je nahajal zadnji */
	
	b	KONEC
	
	
CHILD_EXIST_ERR:
	ldr r0, =E_CHILD_EXIST
	b	KONEC
	
DIR_NOT_EXIST:
	ldr r0, =E_DIR_NOT_EXIST
	b	KONEC
	
NO_CHILD_ERR:
	ldr r0, =E_NO_CHILD
	b	KONEC
	


/* ================================================================
                           SYSTEM CALL CHANGE DIR
   ================================================================
*/	 
SVC_CHGDIR:
	/*
	V registrih R1, R2 in R3 so imena direktorijev po vrsti. Vsi trije registri morajo ali vsebovati ime dira, ali pa biti prazni.

	Popravimo CURRENT, tako da kaže na imenik ki je èim nižje v hierarhiji (ampak ni niè -> register R2 ali R3 ne vsebuje 0)
	*/

	/* ce so v registrih imena direktorijev, je treba najprej dobiti njihove naslove !!!!!!!!!!!!!!!!!!!!!! */


	ldr r6, =D_ROOT
	ldr r6, [r6, #D_CHILD_T]
	
	cmp r1, #0
	beq NO_ATR_ERR
	
SEARCH:						/*zacnemo z iskanjem po tabeli z naslovi (sprehod 3x) */
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO
	cmp r7, #-1				/* check if child table has no more entries */
	beq END_CHILD_T_ERR
	add r6, r6, #4
	
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO
	cmp r7, #-1
	beq END_CHILD_T_ERR
	add r6, r6, #4
	
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO
	cmp r7, #-1
	beq END_CHILD_T_ERR

JUMP:						/*ce ne najdemo pravega se premaknemo na naslednjo tabelo sinov ter ponovimo search */
	add r6, r6, #4
	ldr r6, [r6]
	b SEARCH
	
NAJDENO:						/*element je najden - premaknemo se globje v strukturi, v r6 imamo naslov pravega dira */
	cmp r2, #0
	beq SKOR_KONEC
	ldr r6, [r6, #D_CHILD_T]
	mov r1, r2					/* premaknemo se nivo nižje */
	mov r2, r3
	b SEARCH
	
SKOR_KONEC:
	str r6, [r5, #T_CURDIR]
	b KONEC

NO_ATR_ERR:
	ldr r0, =E_NO_ATR
	b	KONEC

END_CHILD_T_ERR:	
	ldr r0, =E_END_CHILD_T
	b	KONEC


/* ================================================================	
                           SVC_OPENF
   ================================================================
*/		
SVC_OPENF:
	bl SUB_SEARCH
	b SVC_OPEN

	
/* ================================================================
                           SVC_DELF
   ================================================================
*/		
SVC_DELF:
	bl SUB_SEARCH
	b SVC_DEL

	
/* ================================================================
                           SVC_APPENDF
   ================================================================
*/		
SVC_APPENDF:
	bl SUB_SEARCH
	b SVC_APPEND	
	
	
/* ================================================================
                           SUBRUTINE SEARCH
   ================================================================
*/	

/* V r0 dobimo ime datoteke, ki jo moramo poiskati in v r0 podati naslov prvega clustra. */

SUB_SEARCH:

	ldr r6, =D_ROOT
	ldr r6, [r6, #D_CHILD_T]
	
	cmp r1, #0
	beq NO_ATR_ERR
	
SEARCH1:						/*zacnemo z iskanjem po tabeli z naslovi (sprehod 3x) */
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO1
	cmp r7, #-1				/* check if child table has no more entries */
	beq END_CHILD_T_ERR
	add r6, r6, #4
	
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO1
	cmp r7, #-1
	beq END_CHILD_T_ERR
	add r6, r6, #4
	
	ldr r7, [r6,#D_NAME]
	cmp r7,r1
	beq NAJDENO1
	cmp r7, #-1
	beq END_CHILD_T_ERR

						/*ce ne najdemo pravega se premaknemo na naslednjo tabelo sinov ter ponovimo search */
	add r6, r6, #4
	ldr r6, [r6]
	b SEARCH1
	
NAJDENO1:						/*element je najden - premaknemo se globje v strukturi, v r6 imamo naslov pravega dira */
	ldr r0, [r6, #D_TYPE]
	mov r15,r14 				/* shranimo povratni naslov */



/* ================================================================
                           SYSTEM CALL DIR UP
   ================================================================
*/
SVC_DIRUP:
	/*
	CURRENT_DIR nastavimo na oèeta od CURRENT_DIR
	*/
	ldr r9, =CURRENT
	ldr r10, [r9, #T_CURDIR]		/* r10 <- address of current dir*/
	ldr r11, [r10, #D_PARENT]		/* r11 <- pointer to current dir's parent*/
	str r11, [r9, #T_CURDIR]		/* save this pointer to current dir of current task */
	mov r0, #0				/* no error */


KONEC:
	/* Switch to some other task */
	b svc_newtask
	
	
	
/*	INIT:
 treba se je sprehodit po strukturi in nastavit kazalce, zadnjega pa na 0.

	TODO!!!
	INIT metoda!!! - current, dirlist (name->name...->name->0), nastavi root,
	child table ->morajo bit nièle
	remdir treba nastavit to sranje
	disable interrupts
	mkdir remdir za 6 skupino
	current proc + current dir pa te fore
	inlcudi pa to sranje
	dir up ne preverja ce je ze na vrhu
	chdir se sprehaja od currenta dol, ne od roota...
	
*/