; =================================================================
; Project: Student ID Scroll (222438835)
;
; CORRECT HARDWARE MAPPING:
;   PA0=D, PA2=F, PA3=E, PA4=B, PA5=A, PA6=G, PA7=C
;   PB0 = CAT (Digit Select)
;
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE (Recalculated for Scrambled Port A) ---
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
    
    ; Extra spaces for smooth scrolling
    DB 00H      ; [9] Space
    DB 00H      ; [10] Space

START:
    ; 1. CONFIGURE 8255 (All Output)
    MOV DX, 0FFE6H   
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 10       ; 10 steps to scroll everything

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair of digits
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

    ; A. Select Right Digit
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

    ; A. Select Left Digit
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 01H      ; PB0 = 1 (Left)
    OUT DX, AL

    ; B. Send Segment Data (Port A)
    MOV DX, 0FFE0H   ; Port A Address
    POP AX           ; Restore Left Data
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
