; =================================================================
; Project: Scrolling "12345" on 2-Digit PmodSSD
; Connections:
;   Port A (0FFE0H) -> Segments AA-AG
;   Port B (0FFE2H) -> CAT/Select Pin (Connect to PB0)
;   VCC/GND         -> MUST be connected to Trainer Power
; =================================================================

ORG 2000H           ; Program starts at 2000H
    JMP START

; --- DIGIT PATTERNS (Common Cathode) ---
; 0=3FH, 1=06H, 2=5BH, 3=4FH, 4=66H, 5=6DH, Blank=00H
CODES:  
    DB 00H      ; [0] Blank
    DB 06H      ; [1] Number 1
    DB 5BH      ; [2] Number 2
    DB 4FH      ; [3] Number 3
    DB 66H      ; [4] Number 4
    DB 6DH      ; [5] Number 5
    DB 00H      ; [6] Blank

; --- MAIN SETUP ---
START:
    ; Initialize 8255 PPI
    ; Control Word 80H: Port A=Out, Port B=Out, Port C=Out
    MOV DX, 0FFE6H  ; Control Register Address
    MOV AL, 80H     
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Point to start of numbers
    MOV CX, 6       ; We have 6 scrolling steps

SCROLL_SEQUENCE:
    PUSH CX         ; Save scroll counter

    ; Load the pair of numbers to show
    MOV AL, BYTE [SI]    ; Load Left Digit
    MOV BL, BYTE [SI+1]  ; Load Right Digit

    ; Loop to keep this pair visible for a moment (Multiplexing)
    MOV CX, 00FFH   ; Speed: Increase this value to scroll SLOWER

REFRESH_DISPLAY:
    CALL MULTIPLEX  ; Flash Left then Right quickly
    LOOP REFRESH_DISPLAY

    POP CX          ; Restore scroll counter
    INC SI          ; Shift to next number pair
    LOOP SCROLL_SEQUENCE

    JMP MAIN_LOOP   ; Restart sequence

; --- MULTIPLEXER SUBROUTINE ---
; This turns on the Left Digit, waits, then turns on Right Digit
MULTIPLEX:
    PUSH AX
    PUSH DX
    PUSH CX

    ; STEP 1: Turn ON Left Digit (PB0 = LOW)
    MOV DX, 0FFE2H  ; Port B Address
    MOV AL, 00H     ; Signal Low
    OUT DX, AL      
    
    ; Send Left Number to Segments
    MOV DX, 0FFE0H  ; Port A Address
    POP CX          ; (Stack juggle to get original AX)
    POP DX
    POP AX
    PUSH AX
    PUSH DX
    PUSH CX
    OUT DX, AL      ; Output Left Digit Data
    
    CALL DELAY      ; Short wait for visibility

    ; STEP 2: Turn ON Right Digit (PB0 = HIGH)
    MOV DX, 0FFE2H  ; Port B Address
    MOV AL, 01H     ; Signal High (PB0=1)
    OUT DX, AL
    
    ; Send Right Number to Segments
    MOV DX, 0FFE0H  ; Port A Address
    MOV AL, BL      ; Move Right Digit Data (BL) to AL
    OUT DX, AL      ; Output Right Digit Data
    
    CALL DELAY      ; Short wait for visibility

    POP CX
    POP DX
    POP AX
    RET

; --- DELAY SUBROUTINE ---
; Short delay to prevent ghosting/flicker
DELAY:
    PUSH CX
    MOV CX, 0100H   ; Adjust this if display is too dim
WAIT:
    LOOP WAIT
    POP CX
    RET
