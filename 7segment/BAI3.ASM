ORG 0000H
		MOV DPTR, #LED
	RESET:
		MOV R0,#0
	MAIN:
		MOV A,R0
		MOV B,#10
		DIV AB
		;
		MOVC A,@A+DPTR
		MOV P0,A
		;
		MOV A,B
		MOVC A,@A+DPTR
		MOV P2,A
		;
		JB P1.0,$
		JNB P1.0,$
		CALL BLINK
		INC R0
		;
		CJNE R0,#100, MAIN
		JMP RESET
	BLINK:
		MOV R1,#1
		DELAY1:
			MOV R2,#255
		DELAY2:
			MOV R3,#255
			DJNZ R3,$
			DJNZ R2,DELAY2
			DJNZ R1,DELAY1
		RET
	LED:
	DB 0C0H, 0F9H, 0A4H, 0B0H, 99H, 92H, 82H, 0F8H, 80H, 90H	
END