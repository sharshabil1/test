; =================================================================
; Project: Student ID Scroll (8-WIRE CONFIGURATION)
;
; HARDWARE MAPPING:
;   Port A (PA0-PA6): Segments A, B, C, D, E, F, G
;   Port B (PB0):     CAT (Digit Select)
;
; LOGIC:
;   - Port A handles the ENTIRE digit shape (including the middle bar).
;   - Port B toggles the Digit Select (0 = Right, 1 = Left).
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Standard Encoding (A=0, B=1, ... G=6)
;
; '2' (A,B,D,E,G) -> Bits 0,1,3,4,6 = 0101 1011 = 5BH
; '3' (A,B,C,D,G) -> Bits 0,1,2,3,6 = 0100 1111 = 4FH
; '4' (B,C,F,G)   -> Bits 1,2,5,6   = 0110 0110 = 66H
; '8' (All)       -> Bits 0-6       = 0111 1111 = 7FH
; '5' (A,C,D,F,G) -> Bits 0,2,3,5,6 = 0110 1101 = 6DH
; Space           -> 00H

CODES:
    DB 5BH      ; [0] '2'
    DB 5BH      ; [1] '2'
    DB 5BH      ; [2] '2'
    DB 4FH      ; [3] '3'
    DB 66H      ; [4] '4'
    DB 7FH      ; [5] '8'
    DB 7FH      ; [6] '8'
    DB 4FH      ; [7] '3'
    DB 6DH      ; [8] '5'
    DB 00H      ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 steps

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair
    MOV AL, [SI]     ; Left Digit
    MOV BL, [SI+1]   ; Right Digit

    ; --- SPEED ---
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
    PUSH DX

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (CAT PB0 = 0)
    ; ======================================

    ; A. Port B (CAT Low)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 00H      ; PB0 = 0 (Right)
    OUT DX, AL

    ; B. Port A (Segments)
    MOV DX, 0FFE0H   ; Port A Address
    MOV AL, BL       ; Load Right Digit Data
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PB0 = 1)
    ; ======================================

    ; A. Port B (CAT High)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 01H      ; PB0 = 1 (Left)
    OUT DX, AL

    ; B. Port A (Segments)
    MOV DX, 0FFE0H   ; Port A Address
    POP AX           ; Restore Left Digit Data (Original AL)
    PUSH AX          ; Push back
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
