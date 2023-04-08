;------------------------------------------------------------------------------
LEDS		EQU	P1			; diody LED na P1 (0 = ON)
;------------------------------------------------------------------------------
TIME_MS		EQU	10			; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
SEC_100		EQU	30h			; sekundy x 0.01
SEC		EQU	31h			; sekundy
MIN		EQU	32h			; minuty
HOUR		EQU	33h			; godziny
;------------------------------------------------------------------------------

ORG 0

	lcall	init_time		; inicjowanie czasu
time_loop:
	lcall	delay_10ms		; opoznienie 10 ms
	lcall	update_time		; aktualizacja czasu
	jnc	time_loop		; nie bylo zmiany sekund
					; tutaj zmiana sekund
	sjmp	time_loop

leds_loop:
	mov	R7, #50			; opoznienie 500 ms
	lcall	delay_nx10ms
	lcall	leds_change_1		; zmiana stanu diod
	sjmp	leds_loop

;---------------------------------------------------------------------
; Opoznienie 10 ms (zegar 12 MHz) -- 10 000 us
;---------------------------------------------------------------------
delay_10ms:						;2 lcall
	mov	R7, #45					;1
	
external_loop:
	mov R6, #109				;1 * 45
	
	internal_loop:
		djnz R6, internal_loop	;2 * 109 * 45 = 9810
		nop						;1 * 45
	djnz R7, external_loop		;2 * 45 = 90
	
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
delay_nx10ms:

	ret

;---------------------------------------------------------------------
; Opoznienie 10 ms z uzyciem Timera 0 (zegar 12 MHz)
;---------------------------------------------------------------------
delay_timer_10ms:

	ret

;---------------------------------------------------------------------
; Inicjowanie czasu w zmiennych: HOUR, MIN, SEC, SEC_100
;---------------------------------------------------------------------
init_time:

	ret

;---------------------------------------------------------------------
; Aktualizacja czasu w postaci (HOUR : MIN : SEC) | SEC_100
; Przy wywolywaniu procedury co 10 ms
; wykonywana jest aktualizacja czasu rzeczywistego
;
; Wyjscie: CY - sygnalizacja zmiany sekund (0 - nie, 1 - tak)
;---------------------------------------------------------------------
update_time:

	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - wedrujaca w lewo dioda
;---------------------------------------------------------------------
leds_change_1:

	ret

;---------------------------------------------------------------------
; Zmiana stanu LEDS - narastajacy pasek od prawej
;---------------------------------------------------------------------
leds_change_2:

	ret

END