.EQU LCD_PORT	=PORTA    ; Define LCD port
.EQU LCD_DDR	=DDRA     ; Define LCD data direction
.EQU RS			=0        ; Register Select pin
.EQU RW			=1        ; Read/Write pin
.EQU EN			=2        ; Enable pin
.ORG 0            
//INITIALIZE                 
    LDI R16, LOW(RAMEND)  ; Load the low address of RAMEND into R16
    OUT SPL, R16          ; Output the low byte to the stack pointer low
    LDI R16, HIGH(RAMEND) ; Load the high address of RAMEND into R16
    OUT SPH, R16          ; Output the high byte to the stack pointer high
//

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
	LDI R17, 0xC0
	CALL WRITE_COMMAND
// Similarly, write code to display on the second row
//Display line 2
DISPLAY_LINE2:
    LPM R17, Z+					; Load character from the program memory into R17
    CPI R17, $00				; Compare R17 with 0x00
    BREQ LOOP					; Branch to NEWLINE if equal
    CALL WRITE_DATA				; Call to write data to LCD
    RJMP DISPLAY_LINE2			; Repeat the process for the next character
//END MAIN
//LOOP
LOOP:
// This part of the code loops infinitely without any actions, as everything only needs to run once.
RJMP LOOP
//END LOOP

// Subroutine
;------------------------------------------------
// PRESET 
// Input: None 
// Output: None
// Description: Preset for LCD before further execution
PRESET:
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
LINE1:  .DB "VXL-AVR", $00		; Define string for line 1
LINE2:  .DB "GROUP: 3", $00		; Define string for line 2