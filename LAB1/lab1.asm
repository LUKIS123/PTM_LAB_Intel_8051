ORG 0

;---------------------------------------------------------------------
; Test procedury - wywolanie jednorazowe
;---------------------------------------------------------------------
	mov	R0, 	#30h	; liczba w komorkach IRAM 30h i 31h
	
	;lcall	dec_iram	; wywolanie procedury
	;lcall 	inc_xram
	;lcall 	sub_iram
	;lcall	set_bits
	;lcall 	shift_left
	;lcall 	get_code_const
	lcall 	swap_regs
	
	sjmp	$			; petla bez konca

;---------------------------------------------------------------------
; Test procedury - wywolanie powtarzane
;---------------------------------------------------------------------
loop:	
	mov	DPTR, #8000h	; liczba w komorkach XRAM 8000h i 8001h
	lcall	inc_xram	; wywolanie procedury
	sjmp	loop		; powtarzanie

;=====================================================================

;---------------------------------------------------------------------
; Dekrementacja liczby dwubajtowej w pamieci wewnetrznej (IRAM)								zadanie 1
; R0 - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
dec_iram:
	
loop_dec_iram:
	mov R0, #30h	; adres poczatkowy poczatkowy w obszarze w ktorym mozemy przechowywac liczbe	
	
	mov A, @R0		; kopiowanie do akumulatora miejsca na ktore wskazuje adres przechowywany w R0						 => mov A, R0 to przekopiujemy wartosc tego rejestru
	clr C			; czyscimy przeniesienie
	subb A, #1		; na akumulatorze odejmujemy 1 => dziesietnie
	mov @R0, A		; wartosc odstawiamy na z powrotem miejsce
	inc R0			; przejscie do starszej czesci liczby dwubajtowej
	mov A, @R0		; kopiujemy do akumulatora
	subb A, #0		; odejmujemy uzwgledniajac flage cy pozyczki => kiedy wartosc bedzie FF => robimy to aby odjac przeniesienie od starszego bitu
	mov @R0, A		; odstawiamy wartosc z akumulatora na miejsce
	
sjmp loop_dec_iram
	
	ret

;---------------------------------------------------------------------
; Inkrementacja liczby dwubajtowej w pamieci zewnetrznej (XRAM)								zadanie 2
; DPTR - adres mlodszego bajtu (Lo) liczby
;---------------------------------------------------------------------
inc_xram:

loop_inc_xram:
	mov DPTR, #8000h	; do rejestru DPTR przekazujemy miejsce a pamieci XRAM
	
	movx A, @DPTR		; kopiujemy wartosc pamieci pod adresem przechowywanym w rejestrze DPTR do akumulatora za pomoca movx, adres 2 bajtowy wskazuje na 1 bajt pamieci
	clr C				; czyscimy C, w teorii niepotrzbne
	add A, #1			; inkrementacja, add nie uwzglednia flagi C
	movx @DPTR, A		; odstawiamy akumulator do pamieci zewnetrznej pod adresem @DPTR
	inc DPTR			; przesuwamy sie na starszy bit liczby
	movx A, @DPTR		; kopiujemy wartosc pamieci spod zinkrementowanego DPTR
	addc A, #0			; w razie grzyby bylo przeniesienie
	movx @DPTR, A		; odstawiamy na miejsce

sjmp loop_inc_xram

	ret

;---------------------------------------------------------------------
; Odjecie liczb dwubajtowych w pamieci wewnetrznej (IRAM)									zadanie 3
; R0 - adres mlodszego bajtu (Lo) odjemnej A oraz roznicy (A <- A - B)
; R1 - adres mlodszego bajtu (Lo) odjemnika B
;---------------------------------------------------------------------
sub_iram:
	
	; adresy
	mov R0, #30h		; mlodszy bajt odjemnej	A
	mov R1, #56h		; mlodszy bajt odjemnika B
	; wpisujemy liczby pod adres
	mov @R0, #10h
	mov @R1, #2h

loop_sub_iram:
	; adresy
	mov R0, #30h		; mlodszy bajt odjemnej	A
	mov R1, #56h		; mlodszy bajt odjemnika B
	clr C				
	
	
	
	mov A, @R0
	subb A, @R1
	mov @R0, A
	
	
	
	inc R0				; przejscie	dos starszego bitu odjemnej
	mov A, @R0
	subb A, #0
	
	clr C				; niepotrzebne
	inc R1
	subb A, @R1
	mov @R0, A

sjmp loop_sub_iram

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

	;mov R7, #30h
	;mov R6, #56h
	
	; wpisujemy liczby pod adresy
	mov R7, #43h
	mov R6, #21h
	
	mov A, R7
	orl A, #55h		; 55h => kod parzysty w hex = 0101 0101
	mov R7, A
	
	mov A, R6
	orl A, #55h
	mov R6, A
	
	; dziala

	ret

;---------------------------------------------------------------------
; Przesuniecie w lewo liczby dwubajtowej (mnozenie przez 2)									zadanie 5 - pomijam
; Wejscie: R7|R6 - liczba dwubajtowa
; Wyjscie: R7|R6 - liczba po modyfikacji
;---------------------------------------------------------------------
shift_left:
	
	
	
	ret

;---------------------------------------------------------------------
; Pobranie liczby dwubajtowej z pamieci kodu												zadanie 6
; Wejscie: DPTR  - adres mlodszego bajtu (Lo) liczby w pamieci kodu
; Wyjscie: R7|R6 - pobrane dane
;---------------------------------------------------------------------
get_code_const:

	mov DPTR, #code_const
	movc A, @A+DPTR
	mov R7, A
	inc DPTR
	clr A
	movc A, @A+DPTR
	mov R6, A
	
	; dziala

	ret

;---------------------------------------------------------------------
; Zamiana wartosci rejestrow DPTR i R7|R6
; Nie niszczy innych rejestrow
;---------------------------------------------------------------------
swap_regs:

	mov DPTR, #1234h
	mov R7, #78h
	mov R6, #56h
	mov A, #99		; poczatkowa wartosc akumulatora

	push ACC		; wrzaucamy na stos => przesuwamy STACK POINTER o 1, arumentem instrukcji puch jest adres, w tym przypadku adres akumulatora, czyli ACC
	
	mov A, DPH		; kopiujemy wartosc starczego bajtu DPTR
	xch A, R7		; zamieniamy wartosci
	mov DPH, A
	
	mov A, DPL
	xch A, R6
	mov DPL, A		
	
	pop ACC			; akumulator wraca do stanu poczatkowego, STACK POINTER zmiejszamy o 1
	
	ret

;---------------------------------------------------------------------
; Dodanie 10 do danych w obszarze pamieci zewnetrznej (XRAM)
; DPTR - adres poczatku obszaru
; R2   - dlugosc obszaru
;---------------------------------------------------------------------
add_xram:

	ret

;---------------------------------------------------------------------
code_const:
	DB	LOW(1234h)
	DB	HIGH(1234h)

END