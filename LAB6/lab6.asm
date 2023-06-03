;---------------------------------------------------------------------
P5		EQU	0F8h		; adres P5 w obszarze SFR
P7		EQU	0DBh		; adres P7 w obszarze SFR
;---------------------------------------------------------------------
ROWS		EQU	P5		; wiersze na P5.7-4
COLS		EQU	P7		; kolumny na P7.3-0
;---------------------------------------------------------------------
LEDS		EQU	P1		; diody LED na P1 (0=ON)
;---------------------------------------------------------------------

;------------------------------------------------------------------------------
; dodane -> do obslugi wyswietlacza + alokacja pamieci na wyswietlany tekst
;------------------------------------------------------------------------------
WR_CMD		EQU	0FF2Ch		; zapis rejestru komend
WR_DATA		EQU	0FF2Dh		; zapis rejestru danych
RD_STAT		EQU	0FF2Eh		; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh		; odczyt rejestru danych
;------------------------------------------------------------------------------

ORG 0

main_loop:

	lcall	kbd_read
	
	mov		R7, A	; wartosc akumulatora przechowywana
	push	ACC		; aby pozniej przywrocic ACC
	mov		A, R7	; w celu wyswietlenia klawisza na ekranie LCD
	
	lcall	kbd_display		; wyswietlanie na diodach
	pop		ACC
	lcall	kbd_disp_2		; wyswietlenie na LCD
	
	sjmp	main_loop

;---------------------------------------------------------------------
; Uaktywnienie wybranego wiersza klawiatury
;
; Wejscie: A - numer wiersza (0 .. 3)
;---------------------------------------------------------------------
kbd_select_row:
	mov		R0, A
	inc 	R0			; licznik wierszy - zwiekszamy o 1 bo djnz
	mov		A, #11111110b		; maska dla rotacji wybranego wiersza
	cjne	R0, #5, check_cy	; sprawdzenie czy numer jest w zakresie + 1 
								; bo zwiekszone wczesniej

check_cy:	
	jc		set_row			; jesli jest w zakresie, zaczynamy petle
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
	
	mov	A, COLS
	cpl	A
	anl	A, #00001111b

	clr	C
	jz 	end_read_row		; nie zostal wybrany wiersz, konczymy
	
	mov	R1, #0				; licznik odczytanych kolumn
	

row_loop:
	jb	ACC.0, end_row_loop
	rr	A					
	inc	R1					; zwiekszamy kod klawisza
	sjmp	row_loop
	
end_row_loop:
	setb	C					; wlaczamy sygnalizacje wcisnietej klawiszy
	mov	A, R1				; przenosimy kod wybranej klawiszy do akumulatora

end_read_row:
	ret

; -------------------------------- pierwsza wersja --------------------------------
kbd_read_row_v1:
	lcall	kbd_select_row
	clr		C
	
	mov		A, COLS
	orl		A, #11110000b
	anl		A, #11111111b		; same 1 oraz 0 na pozycji gdzie wybrana zostala kolumna

	
	mov		R1, #0				; licznik odczytanych kolumn
	cjne	A, #255, row_loop_v1
	
	sjmp 	end_read_row_v1		; nie zostal wybrany wiersz, konczymy

row_loop_v1:
	jnb		ACC.0, end_row_loop_v1
	rr		A					
	inc		R1					; zwiekszamy kod klawisza
	sjmp	row_loop
	
end_row_loop_v1:
	setb	C					; wlaczamy sygnalizacje wcisnietej klawiszy
	mov		A, R1				; przenosimy kod wybranej klawiszy do akumulatora

end_read_row_v1:
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
	
;--------------------------------------------------------------------	
; Wejscie: CY - stanu klawiatury (0 - brak klawisza, 1 - wcisniety klawisz)
; 	   A  - kod klawisza (0 .. 15)
kbd_disp_2:
	push	ACC
	mov		A, #05h
	lcall	lcd_gotoxy
	pop		ACC	

	jc		display_key

	mov		A, #' '
	lcall 	lcd_write_data
	sjmp	end_kbd_disp2

display_key:
	mov		DPTR, #key_select_char
	movc 	A, @A+DPTR

	lcall	lcd_write_data

end_kbd_disp2:
	ret

;---------------------------------------------------------------------
; Wejscie: A - kod komendy
lcd_write_cmd:
	push	DPH
	push	DPL
	push	ACC
check_stat_loop_1:	
	mov		DPTR, #RD_STAT
	movx	A, @DPTR
	JB		ACC.7, check_stat_loop_1			; sprawdzanie statusu wyswietlacza
	mov		DPTR, #WR_CMD
	pop		ACC
	movx	@DPTR, A
	pop		DPL
	pop		DPH
	; ACC oraz DPTR zostaja nienaruszone
	ret

;---------------------------------------------------------------------
; Wejscie: A - dane do zapisu
lcd_write_data:
	push	DPH
	push	DPL
	push	ACC			; chornione sa DPTR oraz ACC
check_stat_loop_2:	
	mov		DPTR, #RD_STAT
	movx	A, @DPTR
	JB		ACC.7, check_stat_loop_2			; sprawdzanie statusu wyswietlacza
	
	mov		DPTR, #WR_DATA
	pop		ACC
	movx	@DPTR, A
	
	pop		DPL
	pop		DPH
	; ACC oraz DPTR zostaja nienaruszone
	ret
;---------------------------------------------------------------------
; WAZNE: na samym poczatku programu powinno byc lcd init
lcd_init:
	mov		A, #00111000b		; ustawienie trybu pracy
	lcall	lcd_write_cmd
	mov		A, #00000110b		; ustawienie trybu wprowadzania
	lcall	lcd_write_cmd
	mov		A, #00001100b		; ustawienie stanu wyswietlacza, display On/Off D=1, C=0, B=0
	lcall	lcd_write_cmd
	mov		A, #00000001b		; wyczyszczenie wyswietlacza
	lcall	lcd_write_cmd
	ret

;---------------------------------------------------------------------
lcd_gotoxy:
	jnb		ACC.4, lcd_gotoxy_skip		; jesli adres w linii 1 to adres taki jak wspolrzedna x, w przeciwnym wypadku 14 -> 44 czyli 0001 0100 -> 0100 0100
	setb	ACC.6
	clr		ACC.4
lcd_gotoxy_skip:
	setb	ACC.7						; bit komendy
	lcall	lcd_write_cmd
	ret
;---------------------------------------------------------------------

key_select_char:
	db 'A321B654C987D#0*'	

END