//Declare LCD display
.EQU LCD_PORT	=PORTA    ; Define LCD port
.EQU LCD_DDR	=DDRA     ; Define LCD data direction
.EQU RS			=0        ; Register Select pin
.EQU RW			=1        ; Read/Write pin
.EQU EN			=2        ; Enable pin
.DEF ASCII		=R19	  ; ASCII number to transform (48 is decimal)
.DEF UNITS		=R20	  ; Unit number
.DEF TENS		=R21	  ; Tens number
.DEF HUNDS		=R22	  ; Hundreds number
//Declare LED display
.EQU LED_PORT	=PORTB	  ; Define LED port
.EQU LED_DDR	=DDRB	  ; Define LED data direction
//Declare SW	
.EQU SW_PORT	=PORTC	  ; Define SW port
.EQU SW_DDR		=DDRC	  ; Define SW data direction
.EQU SW_PIN		=PINC	  ; Define SW pin data	
.DEF SW_COUNTER =R18	  ; Define counter for button		
//Start at 00
.ORG 00            
//Initialize stack pointer                 
    LDI R16, LOW(RAMEND)  ; Load the low address of RAMEND into R16
    OUT SPL, R16          ; Output the low byte to the stack pointer low
    LDI R16, HIGH(RAMEND) ; Load the high address of RAMEND into R16
    OUT SPH, R16          ; Output the high byte to the stack pointer high
//Initialize LEDs
	LDI R16, 0xFF		  ; Load FF to R16
	OUT LED_DDR, R16	  ; Load LED_DDR = FF --> OUTPUT
	LDI R16, 0x00
	OUT LED_PORT, R16	  ; Turn off LEDS
//Initialize Switch
	CBI SW_DDR, 0			; Clear DDR bit 0 --> bit 0 is INPUT
	SBI SW_PORT, 0			; Set PORT bit 0 --> Pull up register 
//End initialization
//MAIN PROGRAM
MAIN:
	RCALL INIT_LCD
// Call the subroutine to initialize the power (POWERUP_LCD_4BIT) for 4-bit LCD mode. Refer to the curriculum for specifics. Do not call this subroutine; otherwise, the LCD will not display anything.
	RCALL POWERUP_LCD_4BIT	;Use this subroutine to turn on LCD
// Call the subroutine to configure the LCD.
	RCALL INIT_LCD_4BIT		;Configure the LCD
// Call the command to set the DDRAM pointer to 0x00.
	LDI R17, 0x00			;
	RCALL WRITE_COMMAND		;Write command to LCD
// Below is the code to reference the table and display characters from the first row on the LCD until a 0x00 character is encountered.
    LDI ZH, HIGH(LINE1 << 1)   ; Load high byte of LINE1 address into ZH
    LDI ZL, LOW(LINE1 << 1)    ; Load low byte of LINE1 address into ZL
DISPLAY_LINE1:
    LPM R17, Z+                ; Load character from the program memory into R17 and then count up
    CPI R17, $00               ; Compare R17 with 0x00
    BREQ NEWLINE               ; Branch to NEWLINE if equal
    RCALL WRITE_DATA            ; Call to write data to LCD
    RJMP DISPLAY_LINE1         ; Repeat the process for the next character
NEWLINE:
// Write command to move to the next line (command to set DDRAM address at 0x40)
	//LDI R17, 0xC0
	//RCALL WRITE_COMMAND
	LDI ASCII, 48
	LDI SW_COUNTER, 0
// Similarly, write code to display on the second row

//END LCD_MODULE
//LOOP
LOOP:
//Loop to check the input 
	RCALL CHECK_BUTTON
	//
	LDI R17, 0xC0				;Reset cursor at first slot of 2nd line
	RCALL WRITE_COMMAND
	//
	CPI HUNDS, 0
	BRNE H_POS					;Hundreds place
    CPI TENS, 0
    BRNE T_POS					;Tens place
    CPI UNITS, 0
    BRNE U_POS					;Ones place
	
H_POS:
    MOV R17, HUNDS
    ADD R17, ASCII
	CALL WRITE_DATA

T_POS:
    MOV R17, TENS
    ADD R17, ASCII
    CALL WRITE_DATA

U_POS:
    MOV R17, UNITS
    ADD R17, ASCII
	CALL WRITE_DATA

RJMP LOOP
//END LOOP
;------------------------------------------------
// Subroutine
;------------------------------------------------
// INIT_LCD 
// Input: None 
// Output: None
// Description: Preset for LCD before further execution
INIT_LCD:
	LDI R20, $FF			;R20 = 1111 1111
	OUT LCD_DDR, R20		;Load direction = 1 --> DDRA is in output state
	LDI R20, $00			;R20 = 0000 0000
	OUT LCD_PORT, R20		;Clear all values of PORTA
	SBI LCD_PORT, RW		;Set bit to READ
	CBI LCD_PORT, RS		;Clear bit Register Select
	CBI LCD_PORT, EN		;Clear bit Enable
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
    LDI R17, $01				; Command to clear the display
    RCALL WRITE_COMMAND			; Call to write command
	LDI R17, $28				; Command for 4-bit mode, 2 lines, 5x8 dots
    RCALL WRITE_COMMAND			; Call to write command
    LDI R17, $0C				; Command to turn on display, cursor off
    RCALL WRITE_COMMAND			; Call to write command
    //LDI R17, $06              ; Command to shift cursor right
    //CALL WRITE_COMMAND        ; Call to write command
    RET

// CHECK_BUTTON 
// Input: None 
// Output: None
// Description: Check the state of button (with debouncing)
CHECK_BUTTON:
	//Check for the press state
PRESS_BUTTON:
	SBIC SW_PIN, 0				; Skip if button is not pressed
	RJMP PRESS_BUTTON			; Come back to check button's state
	LDI R16, 250				; Load to Delay 10ms
	RCALL DELAY_US				; Call delay subroutine
	SBIC SW_PIN, 0
	RJMP PRESS_BUTTON
	//Check for the release state
RELEASE_BUTTON:
	SBIS SW_PIN, 0				; Skip if button is pressed
	RJMP RELEASE_BUTTON
	LDI R16, 250				; Load to Delay 10ms
	RCALL DELAY_US				; Call delay subroutine
	SBIC SW_PIN, 0
	RJMP RELEASE_BUTTON
	// Continue when the button is debounced
	INC SW_COUNTER				; Press count +1
	OUT LED_PORT, SW_COUNTER	; Output to the LED
	MOV R17, SW_COUNTER
	RCALL BCD_CONV				; Call BCD converter
	RET

// BCD_CONV 
// Input: None 
// Output: None
// Description: Convert number to BCD form
BCD_CONV:
	CLR UNITS
	CLR TENS
	CLR HUNDS
	//
	LDI R16, 10					; Devide for 10
	RCALL DIV10					; Devide 10 subroutine
	MOV UNITS, R16				; Load unit number
	//
	LDI R16, 10					; Devide for 10
	RCALL DIV10					; Devide 10 subroutine
	MOV TENS, R16				; Load ten number
	//
	MOV HUNDS, R17
	//
	RET

// DIV10 
// Input: None 
// Output: None
// Description: Divide 10 subroutine
DIV10:
	CLR R15						; R15: quotient
MINUS_ING:
    SUB R17, R16				; Subtract R16 from R17
    BRCS RESULT					; Branch if carry set (not divisible)
    INC R15						; Increment quotient
    RJMP MINUS_ING				; Continue subtracting
RESULT:
    ADD R17, R16				; Restore the remainder
    MOV R16, R17				; R16: remainder
    MOV R17, R15				; R17: quotient
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
LINE1:  .DB "BUTTON COUNTER: ", $00		; Define string for line 1
