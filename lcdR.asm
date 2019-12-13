
; This is the assignment code given to us
; it is done in 4 bit mode so to work it input your matric no followed by '-' 
; not "'-'" just '-' and then your name
; like so -> 15CJ02800-ALLISON 


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
	MOV R1, #20H		; put data start address in R1
again:
	JNB RI, $			; wait for byte to be received
	CLR RI			; clear the RI flag
	MOV A, SBUF			; move received byte to A
    CJNE A, #'-', new
    MOV @R1, #'-'
        MOV R1, #40H
    JMP again
	
skip:
	MOV @R1, A			; move from A to location pointed to by R1
	INC R1			; increment R1 to point at next location where data will be stored
	JMP again			; jump back to waiting for next byte
new: 
  CJNE A, #0DH, skip	; compare it with 0DH - it it's not, skip next instruction
	JMP finish			; if it is the terminating character, jump to the end of the program

finish:



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


; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB P1.2		; |
	CLR P1.2		; | negative edge on E

	CALL delay		; wait for BF to clear

; send data
	SETB P1.3		; clear RS - indicates that data is being sent to module
	MOV R1, #20H	; data to be sent to LCD is stored in 8051 RAM, starting at location 30H

loop:
	MOV A, @R1		; move data pointed to by R1 to A
    CJNE A, #'-', cont
	JMP nl
nl:
   CLR P1.3
   SETB P1.7
   SETB P1.6
   CLR P1.5
   CLR P1.4

   	SETB P1.2		; |
	CLR P1.2		; | negative edge on E
 
   CLR P1.7
   CLR P1.6
   CLR P1.5
   CLR P1.4

    SETB P1.2		; |
	CLR P1.2		; | negative edge on E

CALL delay
SETB P1.3
MOV R1, #40h
JMP loop


cont:
	JZ end			; if A is 0, then end of data has been reached - jump out of loop
	CALL sendCharacter	; send data in A to LCD module
	INC R1			; point to next piece of data
	JMP loop		; repeat

end:
	JMP $

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





delay:
	MOV R0, #50
	DJNZ R0, $
	RET
