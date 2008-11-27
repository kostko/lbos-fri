Za nas svc_delay potrebujemo v trunk-u se:

- rezervacija prostora za DELAY LIST (seznam [kazalec na TCB in TIMEOUT] vseh procesov,
							ki so klicali SVC_DELAY)
	
	DLYLIST:  .space    80 
	
	
- dodat v ERROR CODES kodo za OVERFLOW

	.equ E_OVRFLV, -5				/* ko pride do OVERFLOW-a (DELAY LIST-e)
	
- dodati strukturo enega DELAY block-a v DELAY LIST-i

	.equ  D_TCB,    0                               /* kazalec na pripadajoc TCB procesa */
	.equ  D_TOUT,   D_TCB+4                         /* vrednost urinih period izkljucitve procesa */
	
======================================================================================================