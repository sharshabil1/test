; =================================================================
; Project: Scrolling Student ID "222438835"
; Hardware: 
;   - Port A (0FFE0H) -> Segments
;   - Port B (0FFE2H) -> CAT / Select (Pin PB0)
;   - VCC/GND -> Connected to Trainer Power
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Digits: 2, 2, 2, 4, 3, 8, 8, 3, 5
; Hex Codes: 
; 2 = 5BH
; 4 = 66H
; 3 = 4FH
; 8 = 7FH
; 5 = 6DH
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
    DB 00H      ; [9] Space (End)

START:
    ; 1. Initialize 8255 PPI (All Outputs)
    MOV DX, 0FFE6H
    MOV AL, 80H
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Point to start of ID
    MOV CX, 9       ; Sequence Length (9 scrolling steps)

SCROLL_SEQUENCE:
    PUSH CX         ; Save counter

    ; Load pair of numbers to display
    MOV AL, BYTE [SI]    ; Left Digit
    MOV BL, BYTE [SI+1]  ; Right Digit

    ; --- SCROLL SPEED DELAY ---
    ; Increased to 01FFH to make it slower and readable
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX          ; Restore counter
    INC SI          ; Move to next number
    LOOP SCROLL_SEQUENCE

    JMP MAIN_LOOP   ; Repeat forever

; --- SUBROUTINE: MULTIPLEXING ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT (CAT = HIGH)
    ; --------------------------------------
    ; Select Right Digit (PB0 = 1)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AH, 01H      ; Signal High
    MOV AL, AH
    OUT DX, AL

    ; Send Segment Data (Right Digit)
    MOV DX, 0FFE0H   ; Port A Address
    MOV AL, BL       ; Get Right Digit Data (BL)
    OUT DX, AL       
    
    CALL DELAY_MUX   ; Wait for eye to see it

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT (CAT = LOW)
    ; --------------------------------------
    ; Select Left Digit (PB0 = 0)
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 00H      ; Signal Low
    OUT DX, AL

    ; Send Segment Data (Left Digit)
    MOV DX, 0FFE0H   ; Port A Address
    POP AX           ; Restore original AX to get AL
    PUSH AX          ; Put it back 
    OUT DX, AL       ; Send Left Digit Data (AL)
    
    CALL DELAY_MUX   ; Wait for eye to see it

    POP DX
    POP AX
    RET

; --- DELAY FOR MULTIPLEXING ---
DELAY_MUX:
    PUSH CX
    ; Increased delay here helps fix "Only one display working"
    MOV CX, 0200H    
WAIT:
    LOOP WAIT
    POP CX
    RET
