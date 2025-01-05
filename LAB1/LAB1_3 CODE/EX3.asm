//Declare LCD port
.EQU LCD_PORT	=PORTA    ; Define LCD port
.EQU LCD_DDR	=DDRA     ; Define LCD data direction
.EQU RS			=0        ; Register Select pin
.EQU RW			=1        ; Read/Write pin
.EQU EN			=2        ; Enable pin
//Declare LED 
.EQU LED_PORT	=PORTD		; Define LED port = PORTD
.EQU LED_DDR	=DDRD		; Define LED data direction = DDRD
//Declare Matrix keypad
.EQU MATRIX_BTN_PORT	=PORTB		; Define Matrix keypad port
.EQU MATRIX_BTN_DDR		=DDRB		; Define matrix keypad data direction
.EQU MATRIX_BTN_PIN		=PINB		; Define matrix keypad pin data
//ELSE
.DEF ASCII		=R19	  ; ASCII number to transform (48 is decimal)
.DEF SW_COUNTER =R18	  ; Define counter for button		
//Start
.ORG 0            
//INITIALIZE                 
    LDI R16, LOW(RAMEND)  ; Load the low address of RAMEND into R16
    OUT SPL, R16          ; Output the low byte to the stack pointer low
    LDI R16, HIGH(RAMEND) ; Load the high address of RAMEND into R16
    OUT SPH, R16          ; Output the high byte to the stack pointer high
//End initializing stack pointer

//MAIN
MAIN:
	CALL PRESET
// Call the subroutine to initialize the power (POWERUP_LCD_4BIT) for 4-bit LCD mode. Refer to the curriculum for specifics. Do not call this subroutine; otherwise, the LCD will not display anything.
	CALL POWERUP_LCD_4BIT	;Use this subroutine to turn on LCD
// Call the subroutine to configure the LCD.
	CALL INIT_LCD_4BIT		;Configure the LCD
// Call the command to set the DDRAM pointer to 0x00.
	LDI R17, 0x00			;
	CALL WRITE_COMMAND		;Write command to LCD
// Below is the code to reference the table and display characters from the first row on the LCD until a 0x00 character is encountered.
    LDI ZH, HIGH(LINE1 << 1)   ; Load high byte of LINE1 address into ZH
    LDI ZL, LOW(LINE1 << 1)    ; Load low byte of LINE1 address into ZL
DISPLAY_LINE1:
    LPM R17, Z+                ; Load character from the program memory into R17 and then count up
    CPI R17, $00               ; Compare R17 with 0x00
    BREQ NEWLINE               ; Branch to NEWLINE if equal
    CALL WRITE_DATA            ; Call to write data to LCD
    RJMP DISPLAY_LINE1         ; Repeat the process for the next character
NEWLINE:
// Write command to move to the next line (command to set DDRAM address at 0x40)
	LDI SW_COUNTER, 0
	LDI ASCII, 48
//END MAIN

//LOOP
LOOP:
	LDI R17, 0xC0
	CALL WRITE_COMMAND
	CALL KEY_RD
RJMP LOOP
//END LOOP

// Subroutine
;------------------------------------------------
// PRESET 
// Input: None 
// Output: None
// Description: Preset for LCD before further execution
PRESET:
	//Setting for LCD
	LDI R20, $FF			;R20 = 1111 1111
	OUT LCD_DDR, R20		;Load direction = 1 --> DDRA is in output state
	LDI R20, $00			;R20 = 0000 0000
	OUT LCD_PORT, R20		;Clear all values of PORTA
	SBI LCD_PORT, RW		;Set bit to READ
	CBI LCD_PORT, RS		;Clear bit Register Select
	CBI LCD_PORT, EN		;Clear bit Enable
	//Setting for MATRIX KEYPAD
	LDI R20, 0x0F			;Load R20 = 0000 1111 (Low nibble is for cols, high nibble is for rows)
	OUT MATRIX_BTN_DDR, R20
	SWAP R20				;Swap R20 --> R20 = 1111 0000 (Set cols to 1 and rows to 0)
	OUT MATRIX_BTN_PORT, R20
	//
	RET

// POWERUP_LCD_4BIT 
// Input: None 
// Output: None
// Description: Subroutine to power up the LCD
POWERUP_LCD_4BIT:
	//Wait for the LCD to turn on --> need delay
    LDI R16, 250              ; Load 250 into R16
    RCALL DELAY_US            ; Call the delay subroutine
	//Command for 8 bit
    LDI R17, $28              ; Load command to initialize LCD in 8-bit mode
    RCALL OUT_COMMAND         ; Call to output command
	//Delay
    LDI R16, 20               ; Load 50 into R16
    RCALL DELAY_US            ; Call the delay subroutine
	//
    RET

// LCD Initialization Subroutine
// Input: None 
// Output: None
// Description: Initializes the LCD
INIT_LCD_4BIT:
    LDI R17, $01              ; Command to clear the display
    CALL WRITE_COMMAND        ; Call to write command
	LDI R17, $28              ; Command for 4-bit mode, 2 lines, 5x8 dots
    CALL WRITE_COMMAND        ; Call to write command
    LDI R17, $0C              ; Command to turn on display, cursor off
    CALL WRITE_COMMAND        ; Call to write command
    //LDI R17, $06              ; Command to shift cursor right
    //CALL WRITE_COMMAND        ; Call to write command
    RET
// Subroutine to write command to LCD
// Input: R17 
// Output: None
// Description: Writes command contained in R17 to the LCD, this goes with OUT_COMMAND
WRITE_COMMAND: 
    PUSH R17                  ; Save R17 on the stack
    ANDI R17, $F0			  ; Output the first 4 bits
    RCALL OUT_COMMAND         ; Call to output command
    POP R17                   ; Restore R17 from the stack
    SWAP R17                  ; Swap nibbles
    ANDI R17, $F0             ; Output the last 4 bits
    RCALL OUT_COMMAND         ; Call to output command
    RET
OUT_COMMAND:
    OUT LCD_PORT, R17        ; Output command to the LCD port
    CBI LCD_PORT, RS         ; Clear RS
    CBI LCD_PORT, RW         ; Clear RW
    SBI LCD_PORT, EN         ; Set Enable
    NOP                       ; No operation
    CBI LCD_PORT, EN         ; Clear Enable
    LDI R16, 20               ; Load delay
    CALL DELAY_US            ; Call delay subroutine
    RET
// Subroutine to write data to LCD
// Input: R17 
// Output: None
// Description: Writes character to LCD according to ASCII code; for example, R17=0x41 displays the letter A
WRITE_DATA: 
    PUSH R17                ; Save R17 on the stack
    ANDI R17, $F0			; Output first 4 bits
    RCALL OUT_DATA          ; Call to output data
    POP R17                 ; Restore R17 from the stack
    SWAP R17                ; Swap nibbles
    ANDI R17, $F0           ; Output last 4 bits
    RCALL OUT_DATA          ; Call to output data
    RET
OUT_DATA:
    OUT LCD_PORT, R17        ; Output data to the LCD port
    SBI LCD_PORT, RS         ; Set RS for data
    CBI LCD_PORT, RW         ; Clear RW --> Write
    SBI LCD_PORT, EN         ; Set Enable
    NOP                      ; No operation
    CBI LCD_PORT, EN         ; Clear Enable
    LDI R16, 20              ; Load delay
    CALL DELAY_US            ; Call delay subroutine
    RET
/* DELAY_US
Input: R16
Output: None
Description: DELAY R16*100 MICROSEC
*/
DELAY_US: 
    MOV R15, R16             ; Move R16 to R15
    LDI R16, 200             ; Load delay value
L1: 
    MOV R14, R16             ; Move delay value to R14
L2: 
    DEC R14                  ; Decrement R14
    NOP                      ; No operation
    BRNE L2                  ; Branch if not equal to zero
    DEC R15                  ; Decrement R15
    BRNE L1                  ; Branch if not equal to zero
RET
//CONTENT
LINE1:  .DB "BUTTON PRESSED: ", $00		; Define string for line 1
//
GET_KEY16:
	LDI R17, 4 ; R17 = Number of column scans
	LDI R20, 0xFE ; Start scanning column 0
SCAN_COL:
	OUT MATRIX_BTN_PORT, R20
	IN R19, MATRIX_BTN_PIN ; Read row status
	IN R19, MATRIX_BTN_PIN ; Read row status again
	ANDI R19, 0xF0 ; Mask upper 4 bits to get row code
	CPI R19, 0xF0 ; Check if a key is pressed?
	BRNE CHK_KEY ; R19 is not F0H, a key is pressed
	LSL R20 ; Scan next column
	INC R20 ; Set LSB = 1
	DEC R17 ; Decrement the number of column scans
	BRNE SCAN_COL ; Continue scanning until all columns are checked
	CLC ; No key pressed, C = 0
	CLR R21 ; R21 = 0 NO KEY PRESSED
	RJMP EXIT ; Exit
;-------------------------------------------------
CHK_KEY:
	SUBI R17, 4 ; Calculate column position
	NEG R17 ; Offset by 2 to get a positive number
	SWAP R19 ; Swap to the lower 4 bits of the row code
	LDI R20, 4 ; R20 holds the scan number for rows
SCAN_ROW:
	ROR R19 ; Rotate right through C to find the 0 bit
	BRCC SET_FLG ; C=0 indicates row position has a key pressed
	INC R17 ; If not, increment row position (add 4)
	INC R17
	INC R17
	INC R17
	DEC R20
	BRNE SCAN_ROW ; Continue scanning all 4 rows
	CLC ; No key pressed, C = 0
	RJMP EXIT ; Exit
SET_FLG:
	SEC ; A key is pressed, C = 1
	SER R21 ; R21 is not zero, indicating a key is pressed
EXIT:
	RET
;-----------------------------------
;------------------------------------------
	; KEY_RD reads the key status
	; Debounce the key press 50 times
	; Use GET_KEY16 to identify the pressed key
	; Exit when a key is pressed!!!
;-------------------------------------------
KEY_RD:
	LDI R16, 50 ; Number of times to check key press
BACK1:
	RCALL GET_KEY16 ; Call function to detect key press
	BRCC KEY_RD ; C=0 means no key pressed, loop again
	DEC R16 ; Decrement the number of key press checks
	BRNE BACK1 ; Loop until the count reaches zero
	PUSH R17

	LDI R17, $C0 ; Move to row 2, position 1
	CALL WRITE_COMMAND
	POP R17
	MOV R24, R17 ; Store the value in R24
	OUT LED_PORT, R24
	RCALL CHUYEN_ASCII
	RCALL WRITE_DATA
	LDI R17, 32
	RCALL WRITE_DATA

WAIT_1:
	LDI R16, 50 ; Number of times to check key press
BACK2:
	RCALL GET_KEY16 ; Call function to detect key press
	BRCS WAIT_1 ; C=1 means a key is still pressed
	DEC R16 ; Decrement the number of key press checks
	BRNE BACK2 ; Loop until the count reaches zero
	;POP R17
	LDI R17, $C0 ; Move to row 2, position 1
	CALL WRITE_COMMAND
	RCALL DISPLAY_FF	
	LDI R24, $FF 
	OUT LED_PORT, R24
	RET
	RET
CHUYEN_ASCII:
	PUSH R18
	CPI R17,0x0A
	BRCS NUM
	LDI R18, 0x37
	RJMP CHAR
NUM:
	LDI R18, 0x30
CHAR:
	ADD R17, R18
	POP R18
	RET
DISPLAY_FF:
	PUSH R17
	LDI R17, 15
	CALL CHUYEN_ASCII
	RCALL WRITE_DATA
	LDI R17, 15
	CALL CHUYEN_ASCII
	RCALL WRITE_DATA
	POP R17
	RET