
; This is the assignment code given to us
; it is done in 4 bit mode so to work it input your name followed by '|' 
; then '-' and then your name, it uses a primitive loop to run 
; like so -> Allison|Kosy-15cj02800


	CLR SM0			; |
	SETB SM1			; | put serial port in 8-bit UART mode

	SETB REN			; enable serial port receiver

	MOV A, PCON			; |
	SETB ACC.7			; |
	MOV PCON, A			; | set SMOD in PCON to double baud rate

	MOV TMOD, #20H		; put timer 1 in 8-bit auto-reload interval timing mode
	MOV TH1, #-3		; put -3 in timer 1 high byte (timer will overflow every 3 us)
	MOV TL1, #-3		; put same value in low byte so when timer is first started it will overflow after approx. 3 us
	SETB TR1			; start timer 1
	MOV R1, #30H		; put data start address in R1
again:
	JNB RI, $			; wait for byte to be received
	CLR RI			; clear the RI flag
	MOV A, SBUF			; move received byte to A
	CJNE A, #0DH, skip	; compare it with 0DH - it it's not, skip next instruction
	JMP finish			; if it is the terminating character, jump to the end of the program
skip:
	MOV @R1, A			; move from A to location pointed to by R1
	INC R1			; increment R1 to point at next location where data will be stored
	JMP again			; jump back to waiting for next byte
finish:
CLR TR1

MOV TMOD, #20H
MOV TH1, #00h
MOV TL1, #00h


; initialise the display
; see instruction set for details


	CLR P1.3		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear


; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear


; display on/o0ff control
; the display is turned on, the cursor is turned on and blinking is turned on
  MOV A, #0Fh
  CALL sendCharacter



; send data
rs:
	SETB P1.3		; clear RS - indicates that data is being sent to module
	MOV R1, #30H	; data to be sent to LCD is stored in 8051 RAM, starting at location 30H

loop:
	MOV A, @R1		; move data pointed to by R1 to A

    CJNE A, #'-', oda ; check for sep character for new line
	JMP nl ; go to nl subroutine if Accumulator = '-'

 

nl:
; call wait subroutine to see data
CALL wait

  ; Set lcd module to recieve command RS->0
   CLR P1.3

; send new line command
 MOV A, #0C0H
 CALL sendCharacter

; set lcd module to recieve data

SETB P1.3
INC R1
JMP loop


oda:

    CJNE A, #'|', cont ;check for sep character | 
	CALL clear; clear lcd if Accumulator = |
	INC R1 ; point to next memory location
	JMP loop ; continue exec
cont:
	JZ end			; if A is 0, then end of data has been reached - jump out of loop
	CALL sendCharacter	; send data in A to LCD module
	INC R1			; point to next piece of data
	JMP loop		; repeat

end:
	CALL clear
	JMP rs

; subroutine to send data to lcd
sendCharacter:
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB P1.2			; |
	CLR P1.2			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB P1.2			; |
	CLR P1.2			; | negative edge on E

	CALL delay			; wait for BF to clear

  RET


; waits for lcd buffer to clear -> 37us
delay:
	MOV R0, #50
	DJNZ R0, $
	RET

; sub routine to clear
clear:

; Set lcd module to recieve command RS->0
   CLR P1.3

   CALL wait

   ; command to move cursor to top left

   MOV A, #80H
   call sendCharacter

; command to clear lcd

    MOV A,#01H
	CALL sendCharacter


; wait for buffer to clear. necessary to wait like 1500ms or so
	MOV R0, #0FFh
	DJNZ R0, $
	MOV R0, #0FFh
	DJNZ R0, $
	MOV R0, #0FFh
	DJNZ R0, $
MOV R0, #0FFh
	DJNZ R0, $


    SETB P1.3

	RET

;Wait to see result.
;  set to wait 6 machine cycles 
; about 3 secs depending on refresh rate
wait:
MOV TH1, #00h
MOV TH1, #00h


 SETB TR1

 ;cycle 1
 JNB TF1, $
 CLR TF1


 ;cycle 2
JNB TF1, $
CLR TF1

;cycle 3
JNB TF1, $
CLR TF1

;cycle 4
 JNB TF1, $
 CLR TF1

 ;cycle 5
JNB TF1, $
CLR TF1

;cycle 6

JNB TF1, $
CLR TF1

; stop timer 
CLR TR1
MOV TH1, #00h
MOV TL1, #00h
RET