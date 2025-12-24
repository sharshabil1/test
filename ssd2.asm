; =================================================================
; Project: Student ID Scroll (222438835)
; Wiring: CUSTOM SCRAMBLED (A=PA5, B=PA4, C=PA7, D=PA0, E=PA3, F=PA2, G=PA6)
;         CAT = PB0
; =================================================================

ORG 2000H
    JMP START

; --- HEX CODE CALCULATIONS ---
; '2' (A,B,D,E,G) -> Bits 5,4,0,3,6 -> 0111 1001 = 79H
; '4' (B,C,F,G)   -> Bits 4,7,2,6   -> 1101 0100 = 0D4H
; '3' (A,B,C,D,G) -> Bits 5,4,7,0,6 -> 1111 0001 = 0F1H
; '8' (All)       -> Bits 7,6,5,4,3,2,0 -> 1111 1101 = 0FDH
; '5' (A,C,D,F,G) -> Bits 5,7,0,2,6 -> 1110 0101 = 0E5H
; Space           -> 00H

CODES:
    DB 79H      ; [0] '2'
    DB 79H      ; [1] '2'
    DB 79H      ; [2] '2'
    DB 0D4H     ; [3] '4'
    DB 0F1H     ; [4] '3'
    DB 0FDH     ; [5] '8'
    DB 0FDH     ; [6] '8'
    DB 0F1H     ; [7] '3'
    DB 0E5H     ; [8] '5'
    
    ; Leading/Trailing Spaces for smooth scroll
    DB 00H      ; [9] Space
    DB 00H      ; [10] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 10       ; 10 Steps (ID + Spaces)

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair of digits
    MOV AL, [SI]     ; Left Digit
    MOV BL, [SI+1]   ; Right Digit

    ; --- SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC SI           ; Next Digit
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (CAT PB0 = 0)
    ; ======================================

    MOV DX, 0FFE2H   ; Port B
    MOV AH, 00H      ; PB0 = 0
    MOV AL, AH
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A
    MOV AL, BL       ; Load Right Digit
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PB0 = 1)
    ; ======================================

    MOV DX, 0FFE2H   ; Port B
    MOV AH, 01H      ; PB0 = 1
    MOV AL, AH
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A
    POP AX           ; Restore Left Digit
    PUSH AX          
    OUT DX, AL       

    CALL DELAY_MUX

    ; Turn off to prevent ghosting
    MOV DX, 0FFE0H
    MOV AL, 00H
    OUT DX, AL

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
