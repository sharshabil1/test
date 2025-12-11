; =================================================================
; FINAL PROJECT: SCROLLING "12345"
; Configuration: (Based on your successful test88 result)
;   - PORT A (0FFE0H) -> Segments AA..AG
;   - PORT B (0FFE2H) -> CAT / Select Pin (Pin PB0)
;   - VCC / GND       -> Connected to Trainer Power
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE (Common Cathode) ---
; 0=3FH, 1=06H, 2=5BH, 3=4FH, 4=66H, 5=6DH, Blank=00H
CODES:  
    DB 00H      ; [0] Blank
    DB 06H      ; [1] Number 1
    DB 5BH      ; [2] Number 2
    DB 4FH      ; [3] Number 3
    DB 66H      ; [4] Number 4
    DB 6DH      ; [5] Number 5
    DB 00H      ; [6] Blank

START:
    ; 1. Initialize Ports
    MOV DX, 0FFE6H  ; Control Register
    MOV AL, 80H     ; All Ports Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Start of data table
    MOV CX, 6       ; Number of shifts

SCROLL_SEQUENCE:
    PUSH CX         ; Save loop counter

    ; Load the two digits to display
    MOV AL, BYTE [SI]    ; Left Digit Data
    MOV BL, BYTE [SI+1]  ; Right Digit Data
    
    ; Multiplex Speed (Hold this frame for a moment)
    MOV CX, 00FFH

MULTIPLEX_FRAME:
    CALL DISPLAY_DIGITS
    LOOP MULTIPLEX_FRAME

    POP CX          ; Restore loop counter
    INC SI          ; Move to next number pair
    LOOP SCROLL_SEQUENCE

    JMP MAIN_LOOP   ; Restart sequence

; --- SUBROUTINE: MULTIPLEXING ---
DISPLAY_DIGITS:
    PUSH AX
    PUSH DX

    ; -------------------------------------------------
    ; STEP 1: SHOW LEFT DIGIT (CAT = LOW)
    ; -------------------------------------------------
    ; A. Select Left Digit (PB0 = 0)
    MOV DX, 0FFE2H  ; Port B
    MOV AH, 00H     ; Signal Low
    MOV AL, AH      
    OUT DX, AL      

    ; B. Send Segment Data to Port A
    MOV DX, 0FFE0H  ; Port A
    POP AX          ; Restore AL (Left Data) from stack
    PUSH AX         ; Put it back for safe keeping
    OUT DX, AL      
    
    CALL DELAY_SMALL

    ; -------------------------------------------------
    ; STEP 2: SHOW RIGHT DIGIT (CAT = HIGH)
    ; -------------------------------------------------
    ; A. Select Right Digit (PB0 = 1)
    MOV DX, 0FFE2H  ; Port B
    MOV AH, 01H     ; Signal High
    MOV AL, AH
    OUT DX, AL      

    ; B. Send Segment Data to Port A
    MOV DX, 0FFE0H  ; Port A
    MOV AL, BL      ; Move Right Data (BL) to AL
    OUT DX, AL      
    
    CALL DELAY_SMALL

    POP DX
    POP AX
    RET

; --- DELAY ---
DELAY_SMALL:
    PUSH CX
    MOV CX, 0080H   ; Adjust this for brightness/flicker
WAIT:
    LOOP WAIT
    POP CX
    RET
