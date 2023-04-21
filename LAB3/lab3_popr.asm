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
	lcall init_time
	mov	R7, #5
	lcall delay_nx10ms
	sjmp $

	lcall	init_time		; inicjowanie czasu
time_loop:
	lcall	delay_10ms		; opoznienie 10 ms
	lcall	update_time		; aktualizacja czasu
	jnc		time_loop		; nie bylo zmiany sekund
							; tutaj zmiana sekund
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
; Poprawa
delay_timer_10ms:
	clr TR0						
	anl	TMOD, #11110000b		
	orl	TMOD, #00000001b		
	mov TL0, #02h				
	mov TH0, #0D9h				

	clr TF0						
	setb TR0

	jnb TF0, $				   	
	nop

	ret

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
; Poprawiona wersja update_time
;---------------------------------------------------------------------
update_time:
	inc SEC_100
	mov R0, SEC_100
	CJNE R0, #100, update_end_no_flag_2
	mov SEC_100, #0
	lcall update_seconds_2
	setb C
	sjmp update_end_2
	
update_end_no_flag_2:
	clr C
update_end_2:
	ret
	
update_seconds_2:
	inc SEC
	mov R0, SEC
	CJNE R0, #60, update_seconds_end_2
	mov SEC, #0

	inc MIN
	mov R0, MIN
	CJNE R0, #60, update_seconds_end_2
	mov MIN, #0

	inc HOUR
	mov R0, HOUR
	CJNE R0, #24, update_seconds_end_2
	mov HOUR, #0
		
update_seconds_end_2:
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - wedrujaca w lewo dioda
;---------------------------------------------------------------------
leds_change_1:
	mov A, LEDS
	cjne A, #11111111b, leds_1_next	; sprawdzenie, czy diody 
									; nie sa w wejsciowej konfiguracji
	clr C
	
leds_1_next:

	rlc A

leds_1_end:
	mov LEDS, A	
	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od prawej
;---------------------------------------------------------------------
leds_change_2:

	mov A, LEDS
	cjne A, #00000000b, leds_2_next_next	; jesli wszystkie diody sie pala
	mov A, #11111111b						; przywroc konfiguracje poczatkowa

	sjmp leds_2_end
	
leds_2_next_next:
	mov A, LEDS								; przypadek w ktorym nalezy zwiekszyc 
											; pasek o kolejna diode
	clr C
	rlc A

leds_2_end:
	mov LEDS, A
	ret

END
	