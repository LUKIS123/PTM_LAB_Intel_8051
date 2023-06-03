;---------------------------------------------------------------------
P5		EQU	0F8h		; adres P5 w obszarze SFR
P7		EQU	0DBh		; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS		EQU	P5		; wiersze na P5.7-4
COLS		EQU	P7		; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
;---------------------------------------------------------------------

ORG 0

main_loop:

	lcall	kbd_read
	lcall	kbd_display
	sjmp	main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
	add		A, #1
	mov		R0, A			; licznik wierszy
	mov		A, #11111110b		; maska dla rotacji wybranego wiersza
	cjne	R0, #5, check_cy	; sprawdzenie czy numer jest w zakresie 

check_cy:	
	jc		set_row				; jesli jest w zakresie, zaczynamy petle
	mov		A, #11111111b		; jesli nie, wylaczamy wszystkie wiersze
	sjmp	end_select_row

set_row:
	rr		A
	djnz	R0, set_row

end_select_row:	
	orl		ROWS, #11110000b
	anl		ROWS, A

	ret

;---------------------------------------------------------------------
; Odczyt wybranego wiersza klawiatury
;
; Wejscie: A  - numer wiersza (0 .. 3)
; Wyjscie: CY - stan wiersza (0 - brak klawisza, 1 - wcisniety klawisz)
;	   		A  - kod klawisza (0 .. 3)
;---------------------------------------------------------------------
kbd_read_row:
	lcall	kbd_select_row
	clr		C
	
	mov		A, COLS
	orl		A, #11110000b
	anl		A, #11111111b		; same 1 oraz 0 na pozycji gdzie wybrana zostala kolumna

	
	mov		R1, #0				; licznik odczytanych kolumn
	cjne	A, #255, row_loop
	
	sjmp 	end_read_row		; nie zostal wybrany wiersz, konczymy

row_loop:
	jnb		ACC.0, end_row_loop
	rr		A					
	inc		R1					; zwiekszamy kod klawisza
	sjmp	row_loop
	
end_row_loop:
	setb	C					; wlaczamy sygnalizacje wcisnietej klawiszy
	mov		A, R1				; przenosimy kod wybranej klawiszy do akumulatora

end_read_row:
	ret

;kbd_read_row:
;	lcall kbd_select_row
;	clr C
;	
;	mov	A, COLS		
;	mov	R1, #0			; licznik odczytanych kolumn
;	mov R0, #4
;	
;row_loop:
;	jnb ACC.0, exit_row_loop	; rotujemy kolumny poki nie znajdziemy wcisniejty klawisz
;	rr	A
;	inc	R1			; zwiekszamy kod klawiszy
;	djnz R0, row_loop
;	sjmp exit_kbd_read_row
;	
;exit_row_loop:
;	setb C			; wlaczamy sygnalizacje wcisnietej klawiszy
;	mov	A, R1			; przenosimy kod wybranej klawiszy do akumulatora
;	
;exit_kbd_read_row:
;	ret

;---------------------------------------------------------------------
; Odczyt calej klawiatury
;
; Wyjscie: CY - stan klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_read:
	mov		R2, #0			; licznik wierszy

kbd_row_loop:
	mov		A, R2			; zaczynamy od pierwszego wiersza
	lcall	kbd_read_row
	jc		kbd_calc_code		; jesli klawisz wcisniety, przechodzimy do obliczenia kodu
	
	inc		R2
	cjne	R2, #4, kbd_row_loop	; sprawdzamy czy licznik wierszy jest w zakresie
	sjmp	end_kbd_read
	
kbd_calc_code:
	mov		R3, A			; kopiujemy kod klawisza w wierszu (0-3)
	mov		A, R2			; przenosimy numer wiersza z licznika
	
	rl		A
	rl		A				; mnozenie nr wiersza * 4
	
	add		A, R3			; dodanie kodu klawisza w wierszu
	setb	C				; sygnalizacje wcisniecia klawiszy

end_kbd_read:
	ret

;---------------------------------------------------------------------
; Wyswietlenie stanu klawiatury
;
; Wejscie: CY - stanu klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A  - kod klawisza (0 .. 15)
;---------------------------------------------------------------------
kbd_display:
	jc		set_leds
	mov		R0, #11111111b
	sjmp	end_kbd_display

set_leds:
	cpl		A
	clr		ACC.7
	mov		R0, A	
	
end_kbd_display:
	mov		A, R0
	mov		LEDS, A
	ret

END
