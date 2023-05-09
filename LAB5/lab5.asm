;------------------------------------------------------------------------------
TIME_MS		EQU	10					; czas w [ms]
CYCLES		EQU	(1000 * TIME_MS)	; czas w cyklach (f = 12 MHz)
LOAD		EQU	(65536 - CYCLES)	; wartosc ladowana do TH0|TL0
;------------------------------------------------------------------------------
CNT_100		EQU	30h		; sekundy x 0.01
SEC			EQU	31h		; sekundy
MIN			EQU	32h		; minuty
HOUR		EQU	33h		; godziny

ALARM_SEC	EQU	34h			; alarm - sekundy
ALARM_MIN	EQU	35h			; alarm - minuty
ALARM_HOUR	EQU	36h			; alarm - godziny
	
;------------------------------------------------------------------------------
ALARM_DURATION	EQU	37h			; alarm - pozostaly czas trwania [s]
;------------------------------------------------------------------------------
SEC_CHANGE	EQU	0				; flaga zmiany sekund (BIT)
;------------------------------------------------------------------------------
LEDS		EQU	P1				; diody LED na P1 (0=ON)
ALARM		EQU	P1.7			; sygnalizacja alarmu
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; dodane -> do obslugi wyswietlacza + alokacja pamieci na wyswietlany tekst
;------------------------------------------------------------------------------
WR_CMD		EQU	0FF2Ch		; zapis rejestru komend
WR_DATA		EQU	0FF2Dh		; zapis rejestru danych
RD_STAT		EQU	0FF2Eh		; odczyt rejestru statusu
RD_DATA		EQU	0FF2Fh		; odczyt rejestru danych
X_DATA		SEGMENT		XDATA
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
CSEG AT 0
	sjmp	start
	
CSEG AT 0Bh
;---------------------------------------------------------------------
; Obsluga przerwania Timera 0
;---------------------------------------------------------------------
T0_int:
	mov		TL0, #LOW(LOAD)
	mov		TH0, #HIGH(LOAD)
	
	push	PSW
	push	ACC
	
	inc 	CNT_100
	mov 	A, CNT_100
	cjne	A, #100, update_seconds_end

update_time:
	setb	SEC_CHANGE
	mov		CNT_100, #0
		
update_seconds:
	inc 	SEC
	mov 	A, SEC
	CJNE 	A, #60, update_seconds_end
	mov 	SEC, #0

	inc 	MIN
	mov 	A, MIN
	CJNE 	A, #60, update_seconds_end
	mov 	MIN, #0

	inc 	HOUR
	mov 	A, HOUR
	CJNE 	A, #24, update_seconds_end
	mov 	HOUR, #0
		
update_seconds_end:
	pop		PSW
	pop		ACC
	
	reti

;---------------------------------------------------------------------
; Start programu
;---------------------------------------------------------------------
start:
	mov 	ALARM_DURATION, #10
	mov		LEDS, #11111111b	; wylaczenie ledow na wszelki wypadek
	lcall	lcd_init			; inicjowanie wyswietlacza
	lcall	timer_init
	lcall	clock_init

;---------------------------------------------------------------------
; Petla glowna programu
;---------------------------------------------------------------------
main_loop:
	jnb SEC_CHANGE, other_tasks	;if sec_change == 0, rob pozostale zadania
	clr SEC_CHANGE
	lcall clock_display
	lcall clock_alarm
	
other_tasks:
	;...
	
	sjmp	main_loop

;---------------------------------------------------------------------
; Inicjowanie Timera 0 w trybie 16-bitowym z przerwaniami
;---------------------------------------------------------------------
timer_init:
	clr TR0
	clr TF0

	anl TMOD,	#11110000b 
	orl TMOD,	#00000001b	; konfiguracja
	
	mov TH0,	#HIGH(LOAD)
	mov TL0,	#LOW(LOAD)
	
	setb ET0 	; odblokowanie przerwan dla timera 0
	setb EA  	; odblokowanie przerwan globalnie
	
	setb TR0	; start
	
	ret

;---------------------------------------------------------------------
; Inicjowanie zmiennych zwiazanych z czasem
;---------------------------------------------------------------------
clock_init:
	; zegar
	mov 	SEC, #59
	mov 	MIN, #59
	mov 	HOUR, #23
	
	; alarm
	mov 	ALARM_SEC,	#10
	mov 	ALARM_MIN,	#0
	mov 	ALARM_HOUR,	#0
	
	mov		CNT_100, #99

	ret

;---------------------------------------------------------------------
; Wyswietlanie czasu - pamietac ze na poczatku programu dodac lcd_init
;---------------------------------------------------------------------
clock_display:
	mov	A, #04h		
;------- ustawienie pozycji wyswietlania
lcd_gotoxy:
	jnb		ACC.4, lcd_gotoxy_skip		; jesli adres w linii 1 to adres taki jak wspolrzedna x, w przeciwnym wypadku 14 -> 44 czyli 0001 0100 -> 0100 0100
	setb	ACC.6
	clr		ACC.4
lcd_gotoxy_skip:
	setb	ACC.7						; bit komendy
	lcall	lcd_write_cmd
	
;------- wyswietlenie godzin
	mov		A, HOUR			; wyswietlenie liczby
	lcall	lcd_dec_2

;------- wyswietlenie dwukropka rozdzielajacego godziny i minuty
	mov		A, SEC
	jb		ACC.0, minuty
	mov		DPTR, #text_dwukropek	; wyswietlenie tekstu
	lcall	lcd_puts
	
;------- wyswietlenie minut
minuty:
	mov		A, MIN			; wyswietlenie liczby
	lcall	lcd_dec_2

;------- wyswietlenie dwukropka rozdzielajacego godziny i sekundy
	mov		A, SEC
	jb		ACC.0, sekundy
	mov		DPTR, #text_dwukropek	; wyswietlenie tekstu
	lcall	lcd_puts
	
sekundy:	
;------- wyswietlenie sekund
	mov		A, SEC			; wyswietlenie liczby
	lcall	lcd_dec_2

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
; Wejscie: A - liczba do wyswietlenia (00 ... 99)
lcd_dec_2:
	mov		B, #10
	div 	AB
	add 	A, #'0'
	mov		DPTR, #number_print1
	movx	@DPTR, A
	mov		A, B
	add 	A, #'0'
	inc		DPTR
	movx	@DPTR, A
	mov		A, #0
	inc		DPTR
	movx	@DPTR, A
	mov		DPTR, #number_print1
	lcall	lcd_puts
	ret
;---------------------------------------------------------------------
; Wejscie: DPTR - adres pierwszego znaku tekstu w pamieci kodu
lcd_puts:
	clr		A
	movc 	A, @A+DPTR
	jz 		koniec_lcd_puts
	lcall	lcd_write_data
	inc		DPTR
	sjmp	lcd_puts
koniec_lcd_puts:
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

;---------------------------------------------------------------------
; Obsluga alarmu
;---------------------------------------------------------------------
clock_alarm:
	jnb		ALARM, clock_alarm_duration		; jesli alarm zostal juz uruchomiony
	
	mov		A, SEC
	cjne 	A, ALARM_SEC, clock_alarm_return
	
	mov		A, MIN
	cjne 	A, ALARM_MIN, clock_alarm_return
	
	mov  	A,	HOUR
	cjne 	A,	ALARM_HOUR, clock_alarm_return
	
	clr  	ALARM				; alarm zostaje wlaczony - sygnalizacja
	dec		ALARM_DURATION
	sjmp	clock_alarm_return

clock_alarm_duration:
	dec		ALARM_DURATION
	mov		A, ALARM_DURATION
	jnz		clock_alarm_return	
	
clock_alarm_off:
	jb   	ALARM,	clock_alarm_return		; alarm wylaczony -> nie - powrot/ tak - wylacz
	setb 	ALARM
	mov		ALARM_DURATION, #10				; reset licznika

clock_alarm_return:
	ret

;---------------------------------------------------------------------
text_dwukropek:
	db	':', 0
; alokacja pamieci na liczbe do wypisania
RSEG	X_DATA
number_print1:
	ds 3

END