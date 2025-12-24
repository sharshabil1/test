; =================================================================
; Project: Student ID Scroll (Standard Wiring)
; 1. Segment Logic: Standard (A-G on PA0-PA6).
; 2. Interface: Match 'ssd.asm' (Port A=Data, Port B=Control).
; 3. Syntax: Fixed 'Undefined Symbol' errors by adding leading 0s.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE (Standard Encoding) ---
; These codes assume:
; PA0=a, PA1=b, PA2=c, PA3=d, PA4=e, PA5=f, PA6=g
;
; '2' = 5BH  (0101 1011)
; '4' = 66H  (0110 0110)
; '3' = 4FH  (0100 1111)
; '8' = 7FH  (0111 1111)
; '5' = 6DH  (0110 1101)
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
    ; Mode 0, All Output = 80H
    MOV DX, 0FFE6H   
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          ; Save loop counter

    ; Load the pair of digits
    MOV AL, [SI]     ; Load Left Digit Data
    MOV BL, [SI+1]   ; Load Right Digit Data

    ; --- SCROLL SPEED ---
    ; Adjust this value if scrolling is too fast/slow
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           ; Restore loop counter
    INC SI           ; Move to next digit
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT (PB0 Active)
    ; --------------------------------------
    MOV DX, 0FFE2H   ; Port B (Control)
    MOV AL, 01H      ; PB0 = 1 (Enable Right)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A (Segments)
    MOV AL, BL       ; Send Right Data (from BL)
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT (PB1 Active)
    ; --------------------------------------
    MOV DX, 0FFE2H   ; Port B (Control)
    MOV AL, 02H      ; PB1 = 1 (Enable Left)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A (Segments)
    POP DX           ; Fix Stack alignment
    POP AX           ; Restore AL (Left Data)
    PUSH AX          ; Push back for RET
    PUSH DX          ; Push back for RET
    
    OUT DX, AL       ; Send Left Data (from AL)
    
    CALL DELAY_MUX

    ; Turn off both to prevent ghosting
    MOV DX, 0FFE2H
    MOV AL, 00H
    OUT DX, AL

    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    ; Short delay to reduce flickering
WAIT:
    LOOP WAIT
    POP CX
    RET
