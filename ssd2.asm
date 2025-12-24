; =================================================================
; Project: Student ID Scroll (SLOW SWITCHING FIX)
;
; HARDWARE MAPPING (Confirmed):
;   Segments: PA0=D, PA2=F, PA3=E, PA4=B, PA5=A, PA6=G, PA7=C
;   CAT:      PB0 (0 = Right Digit, 1 = Left Digit)
;
; FIX: Increased Delay to ensure Right Digit turns on.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE (Scrambled for your wiring) ---
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
    DB 00H      ; [9] Space
    DB 00H      ; [10] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start
    MOV CX, 10       ; 10 Steps

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair of digits
    MOV AL, [SI]     ; Left Digit
    MOV BL, [SI+1]   ; Right Digit

    ; --- SCROLL SPEED ---
    MOV CX, 00FFH    ; Slower scroll for better visibility

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

    ; A. Activate Right Digit (Send 0)
    MOV DX, 0FFE2H   ; Port B
    MOV AL, 00H      ; PB0 = 0 (Right)
    OUT DX, AL

    ; B. Send Segments (Port A)
    MOV DX, 0FFE0H   ; Port A
    MOV AL, BL       ; Load Right Data
    OUT DX, AL       
    
    CALL DELAY_MUX   ; Wait

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PB0 = 1)
    ; ======================================

    ; A. Activate Left Digit (Send 1)
    MOV DX, 0FFE2H   ; Port B
    MOV AL, 01H      ; PB0 = 1 (Left)
    OUT DX, AL

    ; B. Send Segments (Port A)
    MOV DX, 0FFE0H   ; Port A
    POP AX           ; Restore Left Data
    PUSH AX          
    OUT DX, AL       

    CALL DELAY_MUX   ; Wait

    ; Turn off to prevent ghosting
    MOV DX, 0FFE0H
    MOV AL, 00H
    OUT DX, AL

    POP DX
    POP AX
    RET

; --- INCREASED DELAY ---
DELAY_MUX:
    PUSH CX
    ; Increased delay from 0100H to 0800H
    ; This gives the Right Digit more time to turn on.
    MOV CX, 0800H    
WAIT:
    LOOP WAIT
    POP CX
    RET
