; =================================================================
; Project: Student ID Scroll (FIXED STANDARD WIRING)
;
; CORRECT WIRING:
;   Port A (PA0-PA6): Segments A, B, C, D, E, F, G
;   Port B (PB0):     CAT (Digit Select) -> 0=Right, 1=Left
;
; FIXES:
;   - Removed 'CAT' from Port A (it was interfering with segments).
;   - Moved 'CAT' control entirely to Port B (PB0).
;   - Used Standard Hex Codes for the segments.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE (Standard Encoding) ---
; A=Bit0, B=Bit1, C=Bit2, D=Bit3, E=Bit4, F=Bit5, G=Bit6
;
; '2' -> 5BH
; '4' -> 66H
; '3' -> 4FH
; '8' -> 7FH
; '5' -> 6DH
; Space -> 00H

CODES:
    DB 5BH      ; [0] '2'
    DB 5BH      ; [1] '2'
    DB 5BH      ; [2] '2'
    DB 66H      ; [3] '4'
    DB 4FH      ; [4] '3'
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
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load the pair of digits
    MOV AL, [SI]     ; Left Digit Data
    MOV BL, [SI+1]   ; Right Digit Data

    ; --- SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC SI           ; Next digit
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (CAT PB0 = 0)
    ; ======================================

    ; A. Select Right Digit (Port B)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 00H      ; PB0 = 0 (Right)
    OUT DX, AL

    ; B. Send Segment Data (Port A)
    MOV DX, 0FFE0H   ; Port A Address
    MOV AL, BL       ; Load Right Data
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PB0 = 1)
    ; ======================================

    ; A. Select Left Digit (Port B)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 01H      ; PB0 = 1 (Left)
    OUT DX, AL

    ; B. Send Segment Data (Port A)
    MOV DX, 0FFE0H   ; Port A Address
    POP AX           ; Restore Left Data (from Stack)
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
