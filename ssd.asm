; =============================================================
; Project: Scrolling "12345" (MATCHED TO YOUR WORKING WIRING)
;
; HARDWARE SETUP (Based on your working code):
; 1. Port B (0FFE2H) -> Connects to SEGMENTS (AA, AB, AC...)
; 2. Port A (0FFE0H) -> Connects to CAT / SELECT pin
; 3. VCC/GND -> Connected to Power
; =============================================================

ORG 2000H
    JMP START

; --- DIGIT PATTERNS (Common Cathode) ---
; 0=3FH, 1=06H, 2=5BH, 3=4FH, 4=66H, 5=6DH
CODES:  
    DB 00H, 06H, 5BH, 4FH, 66H, 6DH, 00H

START:
    ; Initialize 8255 (A, B, C = Output)
    MOV DX, 0FFE6H
    MOV AL, 80H
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Start of numbers
    MOV CX, 6       ; 6 steps in sequence

SCROLL_SEQ:
    PUSH CX
    MOV AL, BYTE [SI]    ; Left Digit Value
    MOV BL, BYTE [SI+1]  ; Right Digit Value
    
    MOV CX, 00FFH   ; Scroll Speed

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX
    INC SI
    LOOP SCROLL_SEQ
    JMP MAIN_LOOP

; --- DISPLAY SUBROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; -------------------------------------------------
    ; 1. DISPLAY LEFT DIGIT
    ; Logic: Send Segment Data to PORT B, Activate PORT A (Low)
    ; -------------------------------------------------
    
    ; Step A: Send Number to Port B (Segments)
    MOV DX, 0FFE2H  ; PORT B ADDRESS
    PUSH AX         ; Save AX
    OUT DX, AL      ; Send Left Digit Code (AL)
    
    ; Step B: Turn ON Digit 1 (Port A = Low)
    MOV DX, 0FFE0H  ; PORT A ADDRESS
    MOV AL, 0FEH    ; 11111110 (PA0 = LOW)
    OUT DX, AL
    
    CALL DELAY_SMALL

    ; -------------------------------------------------
    ; 2. DISPLAY RIGHT DIGIT
    ; Logic: Send Segment Data to PORT B, Activate PORT A (High)
    ; -------------------------------------------------
    
    ; Step A: Turn OFF Digit 1 first (optional safety)
    MOV AL, 0FFH
    OUT DX, AL

    ; Step B: Send Number to Port B (Segments)
    MOV DX, 0FFE2H  ; PORT B ADDRESS
    POP AX          ; Restore AX to get BL
    MOV AL, BL      ; Move Right Digit Code (BL) to AL
    OUT DX, AL
    
    ; Step C: Turn ON Digit 2 (Port A = High/Toggle)
    ; If PmodSSD uses CAT to toggle, High (1) should switch digits
    MOV DX, 0FFE0H  ; PORT A ADDRESS
    MOV AL, 01H     ; 00000001 (PA0 = HIGH)
    OUT DX, AL
    
    CALL DELAY_SMALL

    POP DX
    POP AX
    RET

DELAY_SMALL:
    PUSH CX
    MOV CX, 0100H
WAIT:
    LOOP WAIT
    POP CX
    RET
