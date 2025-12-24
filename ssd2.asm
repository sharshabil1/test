; =================================================================
; Project: Student ID Scroll (SYNTAX FIXED)
;
; WIRING MAPPING:
;   PA0=AA, PA1=AP(B), PA2=AC, PA3=AD, PA4=AE, PA5=AF
;   PB6=AG
;   PC4=CAT
;
; FIX: Replaced 'CODES[DI+2]' with '[BX+2]' to solve syntax errors.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Format: DB (Port A Value), (Port B Value)
; Based on: PA0=A, PA1=B, PA2=C, PA3=D, PA4=E, PA5=F, PB6=G

CODES:
    DB 1BH, 40H     ; [0] '2'
    DB 1BH, 40H     ; [1] '2'
    DB 1BH, 40H     ; [2] '2'
    
    DB 0FH, 40H     ; [3] '3' 
    DB 26H, 40H     ; [4] '4' 

    DB 3FH, 40H     ; [5] '8'
    DB 3FH, 40H     ; [6] '8'
    DB 0FH, 40H     ; [7] '3'
    DB 2DH, 40H     ; [8] '5'
    DB 00H, 00H     ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, 0        ; Digit Index (0-9)
    MOV CX, 9        ; Scroll Steps

SCROLL_SEQUENCE:
    PUSH CX          

    ; Calculate array offset: SI * 2
    MOV DI, SI
    ADD DI, SI       ; DI now points to the current digit pair in bytes

    ; --- SCROLL SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC SI           
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH DI

    ; Fix for Syntax Error: Load address of CODES into BX
    MOV BX, OFFSET CODES
    ADD BX, DI       ; BX now points to the current Left Digit data

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (PC4 = 0)
    ;    Right Digit is at offset +2 from current BX
    ; ======================================
    
    ; A. Segments A-F (Port A)
    MOV AL, [BX+2]      ; Load Right Digit Port A Value
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, [BX+3]      ; Load Right Digit Port B Value
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = Low)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 00H         ; Bit 4 = 0
    OUT DX, AL
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (PC4 = 1)
    ;    Left Digit is at offset +0 from current BX
    ; ======================================

    ; A. Segments A-F (Port A)
    MOV AL, [BX]        ; Load Left Digit Port A Value
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, [BX+1]      ; Load Left Digit Port B Value
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = High)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 10H         ; Bit 4 = 1
    OUT DX, AL
    
    CALL DELAY_MUX

    ; Turn off to prevent ghosting
    MOV DX, 0FFE0H
    MOV AL, 00H
    OUT DX, AL
    
    POP DI
    POP DX
    POP BX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    
WAIT:
    LOOP WAIT
    POP CX
    RET
