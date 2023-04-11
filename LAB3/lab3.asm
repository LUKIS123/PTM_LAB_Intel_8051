;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0 = ON)
;------------------------------------------------------------------------------
TIME_MS		EQU	10			; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
SEC_100		EQU	30h			; sekundy x 0.01
SEC			EQU	31h			; sekundy
MIN			EQU	32h			; minuty
HOUR		EQU	33h			; godziny
;------------------------------------------------------------------------------

ORG 0
	
	lcall delay_timer_10ms
	; lcall init_time
	mov	R7, #5
	lcall delay_nx10ms
	sjmp $

	lcall	init_time		; inicjowanie czasu
time_loop:
	lcall	delay_10ms		; opoznienie 10 ms
	lcall	update_time		; aktualizacja czasu
	jnc		time_loop		; nie bylo zmiany sekund
	lcall	update_seconds	; tutaj zmiana sekund
	sjmp	time_loop

leds_loop:
	mov	R7, #5					; opoznienie 500 ms
	lcall	delay_nx10ms
	lcall	leds_change_2		; zmiana stanu diod
	sjmp	leds_loop

;---------------------------------------------------------------------
; Opoznienie 10 ms (zegar 12 MHz) -- 10 000 us
;---------------------------------------------------------------------
delay_10ms:						;2 lcall
	mov	R6, #45					;1
	
external_loop:
	mov R5, #109				;1 * 45
	
	internal_loop:
		djnz R5, internal_loop	;2 * 109 * 45 = 9810
		nop						;1 * 45
	djnz R6, external_loop		;2 * 45 = 90
	
	nop
	nop
	nop
	nop
	nop							;1 * 5 bo brakuje 5 cykli maszynowych (mikrosekund)

	ret							;2
								;2 + 1 + 45 + 9810 + 45 + 90 + 5(nop) + 2 = 10 000

;---------------------------------------------------------------------
; Opoznienie n * 10 ms (zegar 12 MHz)
; R7 - czas x 10 ms
;---------------------------------------------------------------------
delay_nx10ms:					;	
	lcall delay_10ms			;
	djnz R7, delay_nx10ms		;
	
	ret

;---------------------------------------------------------------------
; Opoznienie 10 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_10ms:				; 2 lcall
	clr TR0						; 1 zatrzymanie Timera TR0
	anl	TMOD, #11110000b		; 2	wyzerowanie konfiguracji timera 0
	orl	TMOD, #00000001b		; 2	ustawienie konfiguracji timera 0
	; wpisanie wartosci	
	mov TL0, #LOW(LOAD)			; 2
	mov TH0, #HIGH(LOAD)		; 2
	
	; wyzerowanie flagi przepelnienie TF0
	clr TF0						; 1
	; uruchomienie Timera TR0
	setb TR0					; 1
	; Czekanie na ustawienie flagi przepelnienia timera (TF0) -> do tej pory 2+1+2+2+2+2+1+1=13
	mov R7, #16					; 1 cykl + 13 = 14, ale jeszcze + 2 bo ret
inc_by_pevious_cycles:
	inc	TL0							
	djnz R7, inc_by_pevious_cycles	; inkrementacja timera o poprzednie cykle + ret
	
	jnb	TF0, $						; dopoki Timer nie ustawi bitu flagi

	ret								; 2

;---------------------------------------------------------------------
; Inicjowanie czasu w zmiennych: HOUR, MIN, SEC, SEC_100
;---------------------------------------------------------------------
init_time:

	mov	SEC_100, #0
	mov	SEC, #0
	mov	MIN, #0
	mov	HOUR, #0
	
	ret

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | SEC_100
; Przy wywolywaniu procedury co 10 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Wyjscie: CY - sygnalizacja zmiany sekund (0 - nie, 1 - tak)
;---------------------------------------------------------------------
update_time:
	inc SEC_100
	mov R0, SEC_100
	CJNE R0, #100, update_end_no_flag
	mov SEC_100, #0
	setb C
	sjmp update_end
	
update_end_no_flag:
	clr C
update_end:
	ret
	
;---------------------------------------------------------------------
update_seconds:
	inc SEC
	mov R0, SEC
	CJNE R0, #60, update_seconds_end
	mov SEC, #0
	sjmp update_minutes
	
update_seconds_end:
	ret
	
;----------------------------------------------------------------------
update_minutes:
	inc MIN
	mov R0, MIN
	CJNE R0, #60, update_minutes_end
	mov MIN, #0
	sjmp update_hours
	
update_minutes_end:
	ret
	
;---------------------------------------------------------------------
update_hours:
	inc HOUR
	mov R0, HOUR
	CJNE R0, #24, update_hours_end
	mov HOUR, #0
	
update_hours_end:
	ret
	
;---------------------------------------------------------------------
; Zmiana stanu LEDS - wedrujaca w lewo dioda
;---------------------------------------------------------------------
leds_change_1:
	mov A, LEDS
	cjne A, #11111111b, leds_1_next	; sprawdzenie, czy diody nie sa w wejsciowej konfiguracji
	
	clr LEDS.0						; zapalenie ostatniej diody
	sjmp leds_1_end
	
leds_1_next:
	mov A, LEDS			 
	rl A							; przesuniecie zapalonej diody w lewo
	mov LEDS, A	

leds_1_end:
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od prawej
;---------------------------------------------------------------------
leds_change_2:
	mov A, LEDS
	cjne A, #11111111b, leds_2_next_reset	; jesli konfiguracja poczatkowa
	clr LEDS.0								; to zapal diode na najmlodszej pozycji
	sjmp leds_2_end
	
leds_2_next_reset:
	mov A, LEDS
	cjne A, #00000000b, leds_2_next_next	; jesli wszystkie diody sie pala
	mov A, #11111111b						; przywroc konfiguracje poczatkowa
	mov LEDS, A
	sjmp leds_2_end
	
leds_2_next_next:
	mov A, LEDS								; przypadek w ktorym nalezy zwiekszyc pasek o kolejna diode
	rl A									; przesuniecie bitowe
	anl A, #11111110b						; and 11111110
	mov LEDS, A

leds_2_end:
	ret

END
	
;leds_change_1:
;	mov	A, LEDS
;	cjne A, #11111111b, leds_1_end		; sprawdzenie czy diody nie sa w wejsciowej konfiguracji
;	
;	; mov	LEDS, #11111110b			; zapalenie ostatniej diody
;	clr LEDS.0
;	
;leds_1_loop:
;	mov	A, LEDS			 
;	rl A								; przesuniecie diody w lewo
;	mov LEDS, A	
;	sjmp leds_1_loop	
;
;leds_1_end:
;	ret

;leds_change_2:
;	mov	A, LEDS
;	cjne A, #11111111b, leds_2_end		; sprawdzenie czy diody nie sa w wejsciowej konfiguracji
;	sjmp leds_2_next
;	
;leds_2_loop:
;	mov	LEDS, #11111111b
;leds_2_next:
;	clr LEDS.0
;	clr LEDS.1
;	clr LEDS.2
;	clr LEDS.3
;	clr LEDS.4
;	clr LEDS.5
;	clr LEDS.6
;	clr LEDS.7
;sjmp leds_2_loop
;
;leds_2_end:
;	ret
