ORG 0

	sjmp	test_copy_xram_xram	; przyklad testu wybranej procedury

test_sum_iram:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	sum_iram
	sjmp	$

test_copy_iram_iram_inv:
	mov	R0, #30h	; adres poczatkowy obszaru zrodlowego
	mov	R1, #40h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_iram_iram_inv
	sjmp	$

test_copy_xram_iram_z:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #30h	; adres poczatkowy obszaru docelowego
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_iram_z
	sjmp	$

test_copy_xram_xram:
	mov	DPTR, #8000h	; adres poczatkowy obszaru zrodlowego
	mov	R0, #LOW(8010h)	; adres poczatkowy obszaru docelowego
	mov	R1, #HIGH(8010h)
	mov	R2, #4		; dlugosc obszaru
	lcall	copy_xram_xram
	sjmp	$

test_count_even_gt10:
	mov	R0, #30h	; adres poczatkowy obszaru
	mov	R2, #4		; dlugosc obszaru
	lcall	count_even_gt10
	sjmp	$

;---------------------------------------------------------------------
; Sumowanie bloku danych w pamieci wewnetrznej (IRAM)
;
; Wejscie: R0    - adres poczatkowy bloku danych
;          R2    - dlugosc bloku danych
; Wyjscie: R7|R6 - 16-bit suma elementow bloku (Hi|Lo)
;---------------------------------------------------------------------
sum_iram:

	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci wewnetrznej (IRAM) z odwroceniem
;
; Wejscie: R0 - adres poczatkowy obszaru zrodlowego
;          R1 - adres poczatkowy obszaru docelowego
;          R2 - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_iram_iram_inv:
	mov A, R2
	jz koniec_2	;jesli obszar ma dlugosc 0 to zakoncz
	
	clr A
	mov A, R1
	add A, R2
	subb A, #1
	mov R1, A	;R1 wskazuje na ostatni bajt obszaru docelowego
	
loop:
	mov A, @R0
	mov @R1, A
	dec R1
	inc R0
	djnz R2, loop	;petla kopiujaca dane z obszaru zrodlowego do docelowego
	
koniec_2:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku z pamieci zewnetrznej (XRAM) do wewnetrznej (IRAM)
; Przy kopiowaniu powinny byc pominiete elementy zerowe
;
; Wejscie: DPTR - adres poczatkowy obszaru zrodlowego
;          R0   - adres poczatkowy obszaru docelowego
;          R2   - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_iram_z:
	mov A, R2
	jz koniec_3	;jesli obszar ma dlugosc 0 to zakoncz
	
	movx A, @DPTR
	inc DPTR
	jz dalej
	mov @R0, A
	inc R0
dalej:
	djnz R2, copy_xram_iram_z

koniec_3:
	ret

;---------------------------------------------------------------------
; Kopiowanie bloku danych w pamieci zewnetrznej (XRAM -> XRAM)
;
; Wejscie: DPTR  - adres poczatkowy obszaru zrodlowego
;          R1|R0 - adres poczatkowy obszaru docelowego
;          R2    - dlugosc kopiowanego obszaru
;---------------------------------------------------------------------
copy_xram_xram:
	mov A, R2
	jz koniec_4			;jesli obszar ma dlugosc 0 to zakoncz
	
	movx A, @DPTR		;kopiowanie liczby z adresu zrodlowego
	
	push ACC	
	
	mov A, DPH		
	xch A, R1	
	mov DPH, A
	
	mov A, DPL
	xch A, R0
	mov DPL, A		
	
	pop ACC				;DPTR <-> R1|R0 - adres docelowy znajduje sie w DPTR, w akumulatorze znajduje sie liczba z adresu zrodlowego
	
	movx @DPTR, A		;kopiowanie liczby z ACC do adresu docelowego
	
	inc DPTR			;zwiekszenie adresu docelowego
	
	mov A, DPH		
	xch A, R1	
	mov DPH, A
	
	mov A, DPL
	xch A, R0
	mov DPL, A			;DPTR <-> R1|R0 - wracamy do poczatkowych wartosci - DPTR = adres zrodlowy, R1|R0 = adres docelowy
						
	inc DPTR			;zwiekszenie adresu zrodlowego
	
	djnz R2, copy_xram_xram ;kolejne wykonanie
	
koniec_4:
	ret

;---------------------------------------------------------------------
; Zliczanie w bloku danych w pamieci wewnetrznej (IRAM)
; liczb parzystych wiekszych niz 10
;
; Wejscie: R0 - adres poczatkowy bloku danych
;          R2 - dlugosc bloku danych
; Wyjscie: A  - liczba elementow spelniajacych warunek
;---------------------------------------------------------------------
nastepna_liczba:
	dec R2
	inc R0
	
count_even_gt10:
	mov A, R2
	jz koniec_5					;jesli obszar ma dlugosc 0 to zakoncz - mozna sprawdzac bezposrednio innym skokiem zamiast przekladac do A
	
	cjne @R0,#0Bh, next
next:
	jc nastepna_liczba 			;sprawdzenie czy >10
	mov A, @R0
	jb ACC.0, nastepna_liczba	;sprawdzenie czy parzysta
	inc R1
	sjmp nastepna_liczba		;kolejne wykonanie
	
koniec_5:
	mov A, R1
	ret

END