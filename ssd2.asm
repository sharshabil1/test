; =================================================================
; Project: Student ID Scroll (FIXED)
; 1. Syntax Fix: All hex numbers are valid (no 'A6H' errors).
; 2. Logic Fix: Uses Standard Segment codes (like ssd.asm).
; 3. Interface Fix: Uses PB0 and PB1 for multiplexing.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; We use Standard Codes (PA0-PA6). 
; Note: These start with digits (5, 6, 4, 7), so they never cause
; the "Undefined Symbol" error.
;
; '2' = 5BH 
; '4' = 66H 
; '3' = 4FH 
; '8' = 7FH 
; '5' = 6DH 
; Space = 00H

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
    ; Port A = Output (Segments)
    ; Port B = Output (Digit Select)
    ; Control Word: 80H (Mode 0, All Output)
    MOV DX, 0FFE6H   
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          ; Save outer loop counter

    ; Load the pair of digits
    MOV AL, [SI]     ; Load Left Digit Data
    MOV BL, [SI+1]   ; Load Right Digit Data

    ; --- SCROLL SPEED ---
    ; Increase this value (e.g., to 03FFH) if scroll is too fast
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           ; Restore outer loop counter
    INC SI           ; Move to next digit index
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT (PB0 Active)
    ; --------------------------------------
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 01H      ; PB0 = 1 (Turn ON Right Digit)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A Address
    MOV AL, BL       ; Send Right Data (from BL)
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT (PB1 Active)
    ; --------------------------------------
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 02H      ; PB1 = 1 (Turn ON Left Digit)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A Address
    POP DX           ; (Stack fix) Restore registers carefully
    POP AX           ; Restore AL (Left Data)
    
    PUSH AX          ; Push back to keep stack balanced for final RET
    PUSH DX
    
    OUT DX, AL       ; Send Left Data (from AL)
    
    CALL DELAY_MUX

    ; Optional: Turn off both to prevent ghosting
    MOV DX, 0FFE2H
    MOV AL, 00H
    OUT DX, AL

    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    ; Short delay for stable display
WAIT:
    LOOP WAIT
    POP CX
    RET
