ORG 0
;---------------------------------------------------------------------
; Test procedury - wywolanie jednorazowe
;---------------------------------------------------------------------
	;mov	R0, 	#30h	; liczba w komorkach IRAM 30h i 31h
	;lcall	dec_iram	; wywolanie procedury
;---------------------------------------------------------------------

	; test zadania 1
	lcall	loop_dec_iram
	
	; test zadania 2
	;lcall	loop_inc_xram
	
	; test zadania 3
	;lcall 	sub_iram_setup		; ustawienie wartosci rejestrow
	;lcall 	sub_iram			; zadanie 3 => dzialanie procedury mozna obserwowac wpisujac D:30h
	
	; test zadania 4
	;lcall	set_bits_and_shift_left_setup
	;lcall	set_bits
	
	; test zadania 5
	;lcall	set_bits_and_shift_left_setup
	;lcall	shift_left
	
	; test zadania 6
	;mov DPTR, #code_const	; umieszczenie danych w pamieci pod etykieta
	;lcall	get_code_const
	
	; test zadania 7
	;lcall	swap_regs_setup
	;lcall	swap_regs
	
	; test zadania 8
	;mov DPTR, #8000h
	;mov R2, #4h					; wybieramy dlugosc obszaru w jakim chcemy wykonac operacje
	;lcall	add_xram

;---------------------------------------------------------------------	

	sjmp	$			; petla bez konca

; ustawienie wartosci rejestrow dla zadania 3
sub_iram_setup:
	; adresy
	mov R0, #30h		; mlodszy bajt odjemnej	A
	mov R1, #46h		; mlodszy bajt odjemnika B
	
	; wpisujemy liczby pod adres mlodszego bajtu/ niepotrzebne
	mov @R0, #10h
	mov @R1, #2h
ret

; ustawianie wartosci rejestrow dla zadania 4 oraz 5
set_bits_and_shift_left_setup:
	; wpisujemy liczby pod adresy
	mov R7, #43h
	mov R6, #21h
ret

; ustawienie wartosci rejestrow dla zadania 7
swap_regs_setup:
	mov DPTR, #1234h
	mov R7, #78h
	mov R6, #56h
	mov A, #99h		; poczatkowa wartosc akumulatora
ret

;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
;loop:	
;	mov	DPTR, #8000h	; liczba w komorkach XRAM 8000h i 8001h
;	lcall	inc_xram	; wywolanie procedury
;	sjmp	loop		; powtarzanie

; test zadania 1 w petli	
loop_dec_iram:	

	mov R0, #30h		; adres poczatkowy poczatkowy w obszarze w ktorym mozemy przechowywac liczbe
	lcall dec_iram		; dzialanie programu mozna obserwowac poprzez wpisanie D:30h
	
sjmp loop_dec_iram


; test zadania 2 w petli
loop_inc_xram:

	mov DPTR, #8000h	; do rejestru DPTR przekazujemy miejsce a pamieci XRAM
	lcall inc_xram		; dzialanie programu mozna obserwowac poprzez wpisanie X:8000h
	
sjmp loop_inc_xram


;=====================================================================

;---------------------------------------------------------------------
; Dekrementacja liczby dwubajtowej w pamieci wewnetrznej (IRAM)								zadanie 1
; R0 - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
dec_iram:
	
	mov A, @R0			; kopiowanie do akumulatora miejsca na ktore wskazuje adres przechowywany w R0	=> mov A, R0 to przekopiujemy wartosc tego rejestru
	clr C				; czyscimy przeniesienie
	subb A, #1			; na akumulatorze odejmujemy 1 => dziesietnie
	mov @R0, A			; wartosc odstawiamy na z powrotem miejsce
	inc R0				; przejscie do starszej czesci liczby dwubajtowej
	mov A, @R0			; kopiujemy do akumulatora
	subb A, #0			; odejmujemy uzwgledniajac flage cy pozyczki => kiedy wartosc bedzie FF => robimy to aby odjac przeniesienie od starszego bitu
	mov @R0, A			; odstawiamy wartosc z akumulatora na miejsce
	
	ret

; 2 sposob
    dec @R0	
    cjne @R0, #0FFh, not_0
    inc R0
    dec @R0
not_0:
    ret
	
;---------------------------------------------------------------------
; Inkrementacja liczby dwubajtowej w pamieci zewnetrznej (XRAM)								zadanie 2
; DPTR - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
inc_xram:
	movx A, @DPTR		; kopiujemy wartosc pamieci pod adresem przechowywanym w rejestrze DPTR do akumulatora za pomoca movx, adres 2 bajtowy wskazuje na 1 bajt pamieci
	clr C				; czyscimy C, w teorii niepotrzbne
	add A, #1			; inkrementacja, add nie uwzglednia flagi C
	movx @DPTR, A		; odstawiamy akumulator do pamieci zewnetrznej pod adresem @DPTR

	inc DPTR			; przesuwamy sie na starszy bit liczby
	movx A, @DPTR		; kopiujemy wartosc pamieci spod zinkrementowanego DPTR
	addc A, #0			; w razie gdyby bylo przeniesienie
	movx @DPTR, A		; odstawiamy na miejsce

	ret

;---------------------------------------------------------------------
; Odjecie liczb dwubajtowych w pamieci wewnetrznej (IRAM)									zadanie 3
; R0 - adres mlodszego bajtu (Lo) odjemnej A oraz roznicy (A <- A - B)
; R1 - adres mlodszego bajtu (Lo) odjemnika B
;---------------------------------------------------------------------
sub_iram:

	mov A, @R0
	clr C				
	subb A, @R1
	mov @R0, A
	
	inc R0				; przejscie	dos starszego bitu odjemnej
	inc R1

	mov A, @R0
	subb A, @R1
	mov @R0, A

	ret

;---------------------------------------------------------------------
; Ustawienie bitow parzystych (0,2, ..., 14) w liczbie dwubajtowej							zadanie 4
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
set_bits:

	; przed
	; 01000011
	; 00100001
	; wynik
	; 0101 0111
	; 0111 0101
	
	mov A, R7
	orl A, #01010101b		; 55h => kod parzysty w hex = 0101 0101
	mov R7, A
	
	mov A, R6
	orl A, #55h
	mov R6, A

	ret

;---------------------------------------------------------------------
; Przesuniecie w lewo liczby dwubajtowej (mnozenie przez 2)									zadanie 5
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
shift_left:
	
	clr C
	mov A, R6
	rlc A
	mov R6, A
	mov A, R7
	rlc A
	mov R7, A
	
	ret

;---------------------------------------------------------------------
; Pobranie liczby dwubajtowej z pamieci kodu												zadanie 6
; Wejscie: DPTR  - adres mlodszego bajtu (Lo) liczby w pamieci kodu
; Wyjscie: R7|R6 - pobrane dane
;---------------------------------------------------------------------
get_code_const:

	clr A
	movc A, @A+DPTR
	mov R6, A
	inc DPTR
	clr A
	movc A, @A+DPTR
	mov R7, A

	ret

;---------------------------------------------------------------------
; Zamiana wartosci rejestrow DPTR i R7|R6													zadanie 7
; Nie niszczy innych rejestrow
;---------------------------------------------------------------------
swap_regs:

	push ACC		; wrzucamy na stos => przesuwamy STACK POINTER o 1, arumentem instrukcji push jest adres, w tym przypadku adres akumulatora, czyli ACC
	
	mov A, DPH		; kopiujemy wartosc starszego bajtu DPTR
	xch A, R7		; zamieniamy wartosci
	mov DPH, A
	
	mov A, DPL
	xch A, R6
	mov DPL, A		
	
	pop ACC			; akumulator wraca do stanu poczatkowego, STACK POINTER zmiejszamy o 1
	
	ret

; 2 sposob
	push DPH
	pop ACC
	xch A, R7		
	push ACC		; odkladay wartosc R7 na stos
	pop DPH			; pobieramy wartosc ze stosu do DPH
	
	push DPL
	pop ACC
	xch A, R6
	push ACC
	pop DPL
	
	ret
;---------------------------------------------------------------------
; Dodanie 10 do danych w obszarze pamieci zewnetrznej (XRAM)								zadanie 8
; DPTR - adres poczatku obszaru
; R2   - dlugosc obszaru
;---------------------------------------------------------------------
add_xram:
	
	cjne R2, #0, do
	ret
do:
	movx A, @DPTR
	add A, #10
	movx @DPTR, A
	inc dptr
	;djnz R2, add_xram
	dec R2
	sjmp add_xram

	; 2 sposob
	mov A, R2
	jz koniec
loop:
	movx A, @DPTR
	add A, #10
	movx @DPTR, A
	inc DPTR
	djnz R2, loop
koniec:
	ret
;---------------------------------------------------------------------
code_const:
	DB	LOW(1234h)
	DB	HIGH(1234h)

END