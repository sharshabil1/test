; =================================================================
; Project: Student ID Scroll (FORCE G SEGMENT)
;
; PROBLEM: Segment G (AG) on Port B was not lighting up.
; FIX: We now send 'FFH' (All Ones) to Port B instead of just '40H'.
;      This ensures G lights up regardless of which Port B pin used.
;
; WIRING (As you stated):
;   PA0=AA, PA1=AP(B), PA2=AC, PA3=AD, PA4=AE, PA5=AF
;   PB6=AG  (But code will now drive PB0-PB7 just in case)
;   PC4=CAT
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Format: DB (Port A Value), (Port B Value)
;
; We changed the second byte (Port B) from 40H to FFH.
; This turns ON every pin on Port B to force 'G' to light up.

CODES:
    DB 1BH, 0FFH    ; [0] '2' (Port B = All On)
    DB 1BH, 0FFH    ; [1] '2'
    DB 1BH, 0FFH    ; [2] '2'
    
    DB 0FH, 0FFH    ; [3] '3' 
    DB 26H, 0FFH    ; [4] '4' 

    DB 3FH, 0FFH    ; [5] '8'
    DB 3FH, 0FFH    ; [6] '8'
    DB 0FH, 0FFH    ; [7] '3'
    DB 2DH, 0FFH    ; [8] '5'
    
    ; Space must remain 00H (All Off)
    DB 00H, 00H     ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    ; Mode 0, All Ports Output
    MOV DX, 0FFE6H   
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV CX, 9        ; Scroll Steps
    MOV BP, 0        ; Index Counter

SCROLL_SEQUENCE:
    PUSH CX          

    ; Calculate Offset = BP * 2
    MOV AX, BP
    ADD AX, BP       
    MOV DI, AX       ; DI = Offset

    ; --- SCROLL SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC BP           ; Next Index
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX
    PUSH SI

    ; 1. Load Address and Offset
    MOV SI, CODES
    ADD SI, DI       
    
    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (PC4 = 0)
    ; ======================================
    
    ; A. Segments A-F (Port A)
    MOV AL, BYTE [SI+2] ; Load Right Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B) - Sending FFH (All ON)
    MOV AL, BYTE [SI+3] ; Load Right Digit Port B
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = Low)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 00H         ; Bit 4 = 0
    OUT DX, AL
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (PC4 = 1)
    ; ======================================

    ; A. Segments A-F (Port A)
    MOV AL, BYTE [SI]   ; Load Left Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B) - Sending FFH (All ON)
    MOV AL, BYTE [SI+1] ; Load Left Digit Port B
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
    
    POP SI
    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    
WAIT:
    LOOP WAIT
    POP CX
    RET
