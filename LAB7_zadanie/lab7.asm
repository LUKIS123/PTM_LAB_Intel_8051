;------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
KEYS		EQU	P3		; klawisze na P3.2-5
;------------------------------------------------------------

ORG 0

main_loop:	
	lcall klawisze
	lcall read_first_1_right
	lcall ledy
	sjmp main_loop
;------------------------------------------------------------
;wejscie - A
;wyjscie - A, pozycja jedynki 
;------------------------------------------------------------
read_first_1_right:	; jak 1 -> numer bitu 0-7, jak 0 -> 8
	mov R1, #8
	jz wyjscie
	mov R1, #0
petla:	
	rrc A
	jc wyjscie
	inc R1
	sjmp petla
wyjscie:
	mov A, R1
	ret

;------------------------------------------------------------
;wejscie - A, pozycja jedynki
;------------------------------------------------------------
ledy:
	cpl A
	mov LEDS, A

	ret

;------------------------------------------------------------
;wyjscie - A, 1  na miejcu wcisnietego klawisza 
;------------------------------------------------------------
klawisze:
	mov A, KEYS
	cpl A
	anl A, #00111100b
	
	ret


END