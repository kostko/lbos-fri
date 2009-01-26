/*
 * FRI-LBOS ;-)
 * general OS framework (C) 2008 by FRI/OS1/Group8
 */
.global dir_mkdir
.global dir_remdir
.global dir_chdir
.global dir_dirup
.global dir_openf
.global dir_delf
.global dir_appendf
.global dir_init
.global set_current_dir


/* Include structure definitions and static variables */
.include "include/structures.s"
.include "include/at91sam9260.s"
.include "include/macros.s"
.include "include/globals.s"



.text
.code 32
/**
 * Creates a new directory.
 *
 * @param r1 Name of the directory to create
 * @param r2 Set to 0, if directory, or to number of the first cluster in FAT table if file
 */
dir_mkdir:
	
	stmfd sp!, {r1-r12,lr}
	
	DISABLE_IRQ
	ldr r3, =D_DIRLIST
	ldr r8, [r3]									/* r8 <- address of an empty directory */
	cmp r8, #0										/* check if 0, there is no more space */
	bne __mkd_cont1								/* error  */
	
__mkd_no_dir_err:
	ldr r0, =E_NO_DIR
	b return_from_sys
	
__mkd_cont1:
	ldr r4, [r8]									/* r4 <- address of the next empty directory */
	str r4, [r3]									/* update dirlist to next empty dir */
	ENABLE_IRQ
	
	ldr r9, =CURRENT							/* r9 <- address of the current process */
	ldr r10, [r9, #T_CURDIR]  		/* r10 <- address of the current directory */
  cmp r10, #0										/* if current dir is not yet set */
  bne __mkd_cont2
    
  LOAD_ROOT_DIR r5   						/* set current dir to root dir */
	str r5, [r9, #T_CURDIR]
  ldr r10, [r9, #T_CURDIR]
  
__mkd_cont2:
	str r10, [r8, #D_PARENT]			/* set the empty dir's pointer to parent */
	str r1, [r8, #D_NAME]					/* set name */
	str r2, [r8, #D_TYPE]					/* set type */
	mov r4, #0
	str r4, [r8, #D_CHILD_T]   		/* clear his child table, he has no children yet */
  
  add r5, r10, #D_CHILD_T       /* r5 <- address of the current dir's child table */
	ldr r10, [r5]		
	cmp r10, #0										/* if empty, create table */
	beq	__mkd_make_table
	
  mov r5, r10                   /* else move address in r10 into r5 */
__mkd_search:
	ldr r7, [r5], #4							/* start searching for an empty space, automatically increase r5 */
	cmp r7, #0										/* if a child is empty, we found the spot */
	beq __mkd_write
	ldr r7, [r5], #4							/* else we check the next one */
	cmp r7, #0
	beq __mkd_write
	ldr r7, [r5], #4
	cmp r7, #0
	beq __mkd_write
	ldr r7, [r5]
	cmp r7, #0										/* is there another child table? */
	beq __mkd_make_table
	ldr r5, [r7]									/* go to next child table */
	b __mkd_search
	
__mkd_write:										/* r5 - 4 = address of an empty space in child table */
	sub r5, r5, #4
	str r8, [r5]									/* store the newly made dir to this address */
	mov r0, #0
	b return_from_sys


__mkd_make_table:								/* r5 = address for the pointer to new table */
	DISABLE_IRQ
	ldr r6, [r3]									/* r6 <- take another one from the dirlist */
	cmp r6, #0										/* if 0, no more space */
	beq __mkd_no_dir_err							/* error */
	ldr r4, [r6]									/* update dirlist to next empty dir */
	str r4, [r3]
	ENABLE_IRQ

	str r6, [r5]			            /* store the new table to the address */
	str r8, [r6]									/* store the newly made dir to the first space in the table */

	mov r0, #0
	b return_from_sys

	

/**
 * Deletes a directory.
 *
 * @param r1 Name of the directory to delete
 */
dir_remdir:
	/*
	V registru R1 imamo podano ime direktorija, ki ga zelimo zbrisati in smo v current direktoriju. 
	-najdemo zadnjega (je pravi?)
	-najdemo pravega, èe ima sinove -> ERR
	-pravega nastavimo na niè, damo v dirlist
	-zadnjega natavimo na mesto, kjer je bil "pravi"
	-èe je bil zadnji prvi v tabeli, pobrišemo tabelo in nastavimo child_table_p na niè
	*/

	stmfd sp!, {r1-r12,lr}
	
	LOAD_ROOT_DIR r2
	ldr r2, [r2, #D_NAME]
	cmp r2, r1
	beq __rmd_root_del
	
	LOAD_CURRENT_DIR r10
	ldr r2, [r10, #D_CHILD_T]			/* r2 <- child table of the current dir */
	ldr r8, [r10, #D_CHILD_T]
	cmp r2, #0
	beq	__rmd_no_child_err

__rmd_search1:									/* searching for the last dir in the child table */
	ldr r3, [r2], #4
	cmp r3, #0
	beq	__rmd_no_dir_in_list			/* error - no dirs in child table */
	ldr r3, [r2], #4
	add r12, r8, #0								/* if != 0, then we have to delete whole table, r12 <- pointer to the last child table */
	cmp r3, #0
	beq	__rmd_last								/* we found the last one */
	ldr r3, [r2], #4
	mov r12, #0
	cmp r3, #0
	beq	__rmd_last
	ldr r3, [r2], #4
	mov r12, #0
	cmp r3, #0
	beq	__rmd_last
	ldr r2, [r3]									/* jump to next table */
	ldr r8, [r3]									/* pointer to the last child table we went to */ 
	b	__rmd_search1
	
	
__rmd_last:											/* r2 - 8 <- address of the last dir in child table */
	sub r2, r2, #8
	ldr r3, [r2]
  ldr r4, [r3, #D_NAME]					/* check if it is the dir we want to delete */
	cmp r4, r1
	beq __rmd_del_last
	b __rmd_find_correct
	
__rmd_del_last:
	ldr r5, [r3, #D_CHILD_T]			/* check if it has children -> error */
	cmp r5, #0
	bne __rmd_child_exist_err
	
	mov r11, #0
	str r11, [r3, #D_NAME]				/* delete name */
	str r11, [r3, #D_TYPE]				/* delete type */
	str r11, [r3, #D_PARENT]			/* delete parent */
	str r11, [r3, #D_CHILD_T]			/* delete child table */
	str r11, [r2]									/* delete pointer to deleted dir */
	
	DISABLE_IRQ
	ldr r5, =D_DIRLIST						/* move the empty dir back to dirlist */
	ldr r6, [r5]
	str r6, [r3]
	str r3, [r5]
	ENABLE_IRQ
	
	b return_from_sys
	
	
__rmd_find_correct:							/* find the dir we want to delete */
	ldr r3, [r10, #D_CHILD_T]
__rmd_search2:
	ldr r4, [r3], #4
	ldr r4, [r4, #D_NAME]
	cmp r4, r1
	beq __rmd_found								/* we found it */
	cmp r4, #0
	beq	__rmd_dir_not_exist				/* the dir we want to delete doesn't exist at all */
	
	ldr r4, [r3], #4
	ldr r4, [r4, #D_NAME]
	cmp r4, r1
	beq __rmd_found
	cmp r4, #0
	beq	__rmd_dir_not_exist
	
	ldr r4, [r3], #4
	ldr r4, [r4, #D_NAME]
	cmp r4, r1
	beq __rmd_found
	cmp r4, #0
	beq	__rmd_dir_not_exist
	
	ldr r4, [r3]
	ldr	r3, [r4]
	b	__rmd_search2		
	
__rmd_found:										/* we found the one we want to delete */
	sub r3, r3, #4								/* r3 - 4 <- address of the dir in child table */
	ldr r4, [r3]									/* r4 <- address of the dir we want to delete */
	ldr r5, [r4, #D_CHILD_T]
	cmp r5, #0										/* check if it has children */
	bne	__rmd_child_exist_err

	mov r11, #0										/* delete all dir data */
	str r11, [r4, #D_NAME]
	str r11, [r4, #D_TYPE]
	str r11, [r4, #D_PARENT]
	str r11, [r4, #D_CHILD_T]
	
	DISABLE_IRQ
	ldr r5, =D_DIRLIST						/* move the empty dir back to dirlist */
	ldr r6, [r5]
	str r6, [r4]
	str r4, [r5]
	ENABLE_IRQ
	
	str r11, [r2]									/* clear the pointer to the last one */
	ldr r2, [r2]
	str r2, [r3]									/* save last one to the place, where the deleted dir has been */
	
	cmp r12, #0
	bne __rmd_delete_table
	b return_from_sys
	
	
__rmd_delete_table:							/* r12 <- pointer to table */
	ldr r6, [r12]
	mov r11, #0
	str r11, [r6, #C_CHILD1]			/* delete the child table */
	str r11, [r6, #C_CHILD2]	
	str r11, [r6, #C_CHILD3]	
	str r11, [r6, #C_CHILD_T]
	str r11, [r12]
	
	DISABLE_IRQ
	ldr r3, =D_DIRLIST						/* return the child table back to dirlist */ 
	ldr r4, [r3]
	str r4, [r6]
	str r6, [r3]
	ENABLE_IRQ
	
	b	return_from_sys
	
	
__rmd_child_exist_err:
	ldr r0, =E_CHILD_EXIST
	b	return_from_sys
	
__rmd_dir_not_exist:
	ldr r0, =E_DIR_NOT_EXIST
	b	return_from_sys
	
__rmd_no_child_err:
	ldr r0, =E_NO_CHILD
	b	return_from_sys

__rmd_no_dir_in_list:
	ldr r0, =E_NO_DIR_IN_LIST
	b	return_from_sys
	
__rmd_root_del:
	ldr r0, =E_ROOT_DEL
	b	return_from_sys

/**
 * Changes the current directory.
 *
 * @param r1 Name of the highest directory in the hierarchy, under root
 * @param r2 Name of the directory in the second level or 0
 * @param r3 Name of the directory in the third level or 0
 * @param r4 Name of the directory in the forth level or 0
 */ 
dir_chdir:

	stmfd sp!, {r1-r12,lr}
	
	mov r5, #0										/* to stop */

	LOAD_ROOT_DIR r6
	ldr r6, [r6, #D_CHILD_T]      /* r6 <- address of the child table */
  ldr r8, [r6]                  /* jump to first in child table */
	
	cmp r1, #0										/* no attributes */
	beq __chd_no_atr_err
	
__chd_search:										/* search the child table */
	ldr r7, [r8,#D_NAME]
	cmp r7,r1											/* is this the dir we are looking for? */
	beq __chd_found
	cmp r7, #0	  								/* check if child table has no more entries */
	beq __chd_end_childt_err			/* this dir doesn't have requested dir */
	add r6, r6, #4
  ldr r8, [r6]
  
	
	ldr r7, [r8,#D_NAME]
	cmp r7,r1
	beq __chd_found
	cmp r7, #0
	beq __chd_end_childt_err
	add r6, r6, #4
  ldr r8, [r6]
	
	ldr r7, [r8,#D_NAME]
	cmp r7,r1
	beq __chd_found
	cmp r7, #0
	beq __chd_end_childt_err


	add r6, r6, #4								/* if we havent't found it already, move to the next child table */
	ldr r6, [r6]
  ldr r8, [r6]
	b __chd_search
	
__chd_found:										/* found the correct dir (in r8), look for next dir r2 != 0 */
	cmp r2, #0
	beq __chd_over
	ldr r6, [r8, #D_CHILD_T]			/* move to this dir's child table */
  ldr r8, [r6]
	mov r1, r2										/* move the names of the dirs */
	mov r2, r3
	mov r3, r4
	mov r4, r5
	b __chd_search
	
__chd_over:
  STORE_CURRENT_DIR r8					/* store this dir into current dir */
	b return_from_sys

__chd_no_atr_err:
	ldr r0, =E_NO_ATR
	b	return_from_sys

__chd_end_childt_err:	
	ldr r0, =E_END_CHILD_T
	b	return_from_sys


/**
 * Opens a file.
 *
 * @param r0 Name of the file to open
 */ 	
dir_openf:
	bl __search_subroutine
	/*b svc_open*/

	
/**
 * Deletes a file.
 *
 * @param r0 Name of the file to delete
 */ 	
dir_delf:
	bl __search_subroutine
	/*b svc_del*/

	
/**
 * Appends to a file.
 *
 * @param r0 Name of the file to append to
 */ 		
dir_appendf:
	bl __search_subroutine
	/*b svc_append*/
	
	

/**
 * Searches for a file and puts the number of the first cluster in FAT into r0
 *
 * @param r0 Name of the file we are searching for
 */
__search_subroutine:

	stmfd sp!, {r1-r3,lr}

	LOAD_ROOT_DIR r1
	ldr r1, [r1, #D_CHILD_T]			/* address of the child table */
	ldr r3, [r1]									/* jump to the child table */
	
	cmp r0, #0										/* no attributes? */
	beq __chd_no_atr_err
	
__srch_loop:										/* search child table */
	ldr r2, [r3,#D_NAME]
	cmp r2,r0
	beq __srch_found							/* have we found it? */
	cmp r2, #0										/* check if child table has no more entries */
	beq __chd_end_childt_err
	add r1, r1, #4
	ldr r3, [r1]
	
	ldr r2, [r3,#D_NAME]
	cmp r2,r0
	beq __srch_found
	cmp r2, #0
	beq __chd_end_childt_err
	add r1, r1, #4
	ldr r3, [r1]
	
	ldr r2, [r3,#D_NAME]
	cmp r2,r0
	beq __srch_found
	cmp r2, #0
	beq __chd_end_childt_err


	add r1, r1, #4								/* if we havent't found it already, move to the next child table */
	ldr r1, [r1]
	ldr r3, [r1]
	b __srch_loop
	
__srch_found:										/*we found it, load the number of the first cluster into r0 */
	ldr r0, [r3, #D_TYPE]	
	ldmfd sp!, {r1-r3,pc}



/**
 * Changes the current directory to one directory up, to his parent.
 */
dir_dirup:
	
	stmfd sp!, {r1-r12,lr}
	
	ldr r9, =CURRENT
	ldr r10, [r9, #T_CURDIR]		/* r10 <- address of current dir*/
	ldr r11, [r10, #D_PARENT]		/* r11 <- pointer to current dir's parent*/
	cmp r11, #0									/* check if not root */
	beq __du_root_dirup_err
  STORE_CURRENT_DIR r11       /* save this pointer to current dir of current task */
	mov r0, #0									/* no error */
	b return_from_sys

__du_root_dirup_err:
	ldr r0, =E_ROOT_DIRUP
	b return_from_sys

	
return_from_sys:							/* return from system call */
	ENABLE_IRQ
	ldmfd sp!, {r1-r12,pc}
		
	
/**
 * Sets current dir to root directory.
 *
 * @param r2 Pointer to task's TCB
 */
set_current_dir:
	stmfd sp!, {r1-r2,lr}				/* store work registers */
	
	LOAD_ROOT_DIR r1						/* load root address */
	str r1, [r2, #T_CURDIR]
	
	ldmfd sp!, {r1-r2,pc}

/**
 * Initializes the needed data structures (root directory, list of empty directories) etc.
 */	
dir_init:

  DISABLE_IRQ

	stmfd sp!, {r3-r5,lr}				/* store work registers */
	
	LOAD_ROOT_DIR r3						/* set up root directory */
	ldr r4, =ROOT_NAME
	str r4, [r3, #D_NAME]
	mov r4, #0
	str r4, [r3, #D_TYPE]
	str r4, [r3, #D_PARENT]
	str r4, [r3, #D_CHILD_T]
	
	
	mov r5, #50									/* set up pointers for list of empty directories */
  ldr r3, =D_DIRLIST
	add r4, r3, #4
	str r4, [r3]
	add r3, r3, #4							/* leave a blank for the pointer to first empty structure in the list */
	
__dir_init_loop:
	add r4, r3, #D_SIZE
	str r4, [r3]
	mov r3, r4
	sub r5, #1
  cmp r5, #0
	bne __dir_init_loop
	mov r4, #0
	str r4, [r3]	

	ENABLE_IRQ
	
	ldmfd sp!, {r3-r5,pc}
	
ROOT_NAME: .asciz "ROOT"
