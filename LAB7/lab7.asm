;---------------------------------------------------------------------
OFFSET		EQU	('a' - 'A')	; offset w tablicy ASCII
;---------------------------------------------------------------------

ORG 0

test_reverse_iram:
	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	fill_iram

	mov	R0, #30h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy
	lcall	reverse_iram

test_rotate_xram:
	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	fill_xram

	mov	DPTR, #8000h	; adres poczatkowy tablicy
	mov	R2, #8		; dlugosc tablicy R3|R2
	mov	R3, #0
	lcall	rotate_xram

test_string:
	mov	DPTR, #text	; adres poczatkowy stringu (CODE)
	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	copy_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	reverse_string

	mov	R0, #30h	; adres poczatkowy stringu (IRAM)
	lcall	convert_letters

	sjmp	$

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_iram:
	mov		A, #1					; licznik ciagu liczb 1,2,3...
	cjne	R2, #0,	loop_fill_iram	; podana dlugosc 0
	sjmp	exit_fill_iram
	
loop_fill_iram:
	mov		@R0, A
	inc		R0
	inc		A
	djnz	R2, loop_fill_iram
	
exit_fill_iram:	
	ret

;---------------------------------------------------------------------
; Wypelnianie tablicy ciagiem liczbowym 1,2,3, ... (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
fill_xram:
	mov		A, #1		; licznik
	sjmp	loop_fill_xram
	
dec_Lo_only:
	dec		R2			; zmniejszamy dlugosc tablicy (Low)

loop_fill_xram:
	; sprawdzenie czy licznik nie jest zerowy
	cjne	R2, #0, not_zero_len
	cjne	R3, #0, not_zero_len
	sjmp 	exit_fill_xram

not_zero_len:
	movx	@DPTR, A		; przenosimy licznik do DPTR
	inc		DPTR
	inc		A
	
	cjne	R2, #0, dec_Lo_only

	dec		R2			; zmniejszamy dlugosc tablicy (Low)
	dec 	R3			; zmniejszamy dlugosc tablicy (High)
	sjmp	loop_fill_xram
	
exit_fill_xram:
	ret

;---------------------------------------------------------------------
; Odwracanie tablicy w pamieci wewnetrznej (IRAM)
; Wejscie:  R0 - adres poczatkowy tablicy
;           R2 - dlugosc tablicy
;---------------------------------------------------------------------
reverse_iram:
	mov 	A, R2
	jz		end_reverse_iram		; jesli obszar ma dlugosc 0 to zakoncz
	
	mov		A, R0
	add		A, R2
	subb	A, #1
	mov		R1, A		; R1 wskazuje na ostatni adres tablicy
	
	mov		A, R2
	mov		B, #2
	div		AB
	mov		R2, A
	
loop_reverse_iram:
	mov		A, @R0
	xch		A, @R1
	mov		@R0, A

	dec		R1
	inc		R0
	
	djnz	R2, loop_reverse_iram
	
end_reverse_iram:
	ret

;---------------------------------------------------------------------
; Rotacja w prawo tablicy w pamieci zewnetrznej (XRAM)
; Wejscie:  DPTR  - adres poczatkowy tablicy
;           R3|R2 - dlugosc tablicy
;---------------------------------------------------------------------
rotate_xram:
	mov		A, DPL
	add		A, R2			; obliczamy adres koncowy XRAM (Low)
	mov		R0, A

	mov		A, DPH
	addc	A, R3			; obliczamy adres koncowy XRAM (High)
	mov		R1, A		
	
	mov		A, R0			; sprawdzenie czy nie mamy zwiekszyc High
	dec		R0
	jnz		skip_dec_Hi
	dec		R1
							; R1|R0 - adres koncowy
	
skip_dec_Hi:
;	clr		C
;	mov		A, R3			; dzielenie przez 2 dlugosci tablicy
;	rrc		A
;	mov		R3, A
;	
;	mov		A, R2
;	rrc		A
;	mov		R2, A
	
; do dptr adres ostatniego elementu	
	mov		A, DPH
	xch		A, R1
	mov		DPH, A
	mov		A, DPL
	xch		A, R0
	mov		DPL, A
	
	movx	A, @DPTR	; w ACC wartosc ostatniego elementu
	mov		R4, A		; przechowalnia w R4
	
; do dptr adres pierwszego elemetu
	mov		A, DPH
	xch		A, R1
	mov		DPH, A
	mov		A, DPL
	xch		A, R0
	mov		DPL, A

rotate_xram_loop:
	mov 	A, R2			; sprawdzenie czy licznik nie jest zerowy
	orl 	A, R3
	jz		end_rotate_xram

	movx	A, @DPTR
	xch		A, R4		; w ACC wartosc ktora nalezy wpisac, do przechowali trafia wartosc spod aktualnego adresu
	movx	@DPTR, A
	
	inc		DPTR
	
	mov 	A, R2
	dec		R2			; zmniejszamy dlugosc tablicy (Low)
	jnz 	rotate_xram_loop
	dec 	R3			; zmniejszamy dlugosc tablicy ((High)	
	
	sjmp	rotate_xram_loop
	
end_rotate_xram:
	ret

;---------------------------------------------------------------------
; Kopiowanie stringu z pamieci programu (CODE) do pamieci IRAM
; Wejscie:  DPTR - adres poczatkowy stringu (CODE)
;           R0   - adres poczatkowy stringu (IRAM)
;---------------------------------------------------------------------
copy_string:
	clr		A
	movc 	A, @A+DPTR		; pobieramy element
	mov		@R0, A			; przenosimy do IRAM
	
	jz		end_copy_string			; byte 0 -> koniec
	inc		R0
	inc		DPTR
	sjmp	copy_string

end_copy_string:
	ret

;---------------------------------------------------------------------
; Odwracanie stringu w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
;---------------------------------------------------------------------
reverse_string:
	mov		R2, #0			; dlugosc tablicy
	mov		A, R0			; oryginalny adres zostaje zachowany w R0
	mov		R1, A

loop_calc_string_len:
	cjne	@R1, #0, continue_loop	; sprawdzenie czy wystapil byte 0
	sjmp	start_reverse
	
continue_loop:						; przechodzimy do nastepnej komorki
	inc		R1
	inc		R2
	sjmp	loop_calc_string_len

start_reverse:
	lcall	reverse_iram

	ret

;---------------------------------------------------------------------
; Zamiana malych liter na duze a duzych na male
; w stringu umieszczonym w pamieci IRAM
; Wejscie:  R0 - adres poczatkowy stringu
;---------------------------------------------------------------------
convert_letters:
	clr		C
	mov		A, @R0
	jz		end_convert_letters
	cjne	A, #'A', label1
label1:
	jc		go_next
	clr		C
	cjne	A, #'Z' + 1, label2
label2:
	jnc		label3
	; znak jest wielka litera
	add		A, #OFFSET
	mov		@R0, A
	sjmp	go_next
label3:
	; znak nie jest wielka litera
	clr		C
	cjne	A, #'a', label4
label4:
	jc		go_next
	clr		C
	cjne	A, #'z' + 1, label5
label5:
	jnc		go_next
	; znak jest mala litera
	clr		C
	subb	A, #OFFSET
	mov		@R0, A

go_next:
	inc		R0
	sjmp	convert_letters
	
end_convert_letters:
	ret

text:
	DB	'Hello world 0123456789', 0

END