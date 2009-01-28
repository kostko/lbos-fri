.section task_code, "ax"
.code 32

/* Include structure definitions and static variables */
.include "include/structures.s"

task1:

  ldr r1,=TEST
  swi #SYS_CREATEF                /*funkcija poisce prvo prazno gruco, in jo vrne v r2*/
  add r12, r2, #0           /*shranimo r1 v r11, lahk bi tud kako drugac store/load maybe*/
  
  add r0, r12, #0        /*ponovi vajo, le z r0, ker tako zahteva svc_open*/
  swi #SYS_OPEN
  
  mov r3, #113
  str r3,[r4]        /*r4 vsebuje naslov fs_working v open*/
  swi #SYS_WRITE
  
  swi #SYS_CREATEF       
  add r11, r2, #0       
  
  add r0, r11, #0
  swi #SYS_OPEN
  
  mov r5,#0        /*stevec za zanko*/
  mov r3,#1

__tst1fs_loop:        /*v fs_working shranimo*/
  str r3,[r4],r5        /*samo 1ke*/
  add r5,r5,#1        /*to ponovimo*/
  cmp r5, #300        /*300krat*/
  bne __tst1fs_loop   
  
  mov r10,#2        /*v r10 shranim stevilo novih gruc, v tem primeru rabim 2*/
  swi #SYS_APPEND
  
  mov r10,#1        /*odstranimo zadnjo gruco*/
  swi #SYS_TRUNCATE        /*ostaneta nam dve cisto polni gruci*/
  
  add r0, r11, #0
  swi #SYS_DEL            /*zbrisemo datoteko*/


/*************************************************************
 *      TASK DATA SECTION - For static task structures       *
 *************************************************************/
.section task_data, "aw"
/* Per-task data structures may be defined below */

TEST: .asciz "file1"

