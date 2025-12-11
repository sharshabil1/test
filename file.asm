; =============================================================
; DIAGNOSTIC TEST: FLASHLIGHT MODE
; Description: Turns ALL segments ON. Displays "88".
;              Used to verify wiring is correct.
;
; WIRING CHECKLIST:
; 1. Pmod VCC -> Trainer 5V
; 2. Pmod GND -> Trainer GND
; 3. Pmod AA-AG -> Port A (PA0-PA6)
; 4. Pmod CAT   -> Port B (PB0) << CRITICAL
; =============================================================

ORG 2000H
    JMP START

START:
    ; 1. CONFIGURE PORTS
    MOV DX, 0FFE6H  ; Control Register Address
    MOV AL, 80H     ; Set All Ports (A, B, C) to OUTPUT
    OUT DX, AL

    ; 2. TURN ON SEGMENTS (PORT A)
    ; We send FFH (11111111) to turn every single segment ON.
    MOV DX, 0FFE0H  ; Port A Address
    MOV AL, 0FFH    ; All 1s = All Lights ON
    OUT DX, AL

LOOP_TOGGLE:
    ; 3. ACTIVATE LEFT DIGIT
    MOV DX, 0FFE2H  ; Port B Address (Connected to CAT)
    MOV AL, 00H     ; CAT = LOW
    OUT DX, AL      
    
    CALL DELAY      ; Wait so eyes can see it

    ; 4. ACTIVATE RIGHT DIGIT
    MOV DX, 0FFE2H  ; Port B Address
    MOV AL, 01H     ; CAT = HIGH
    OUT DX, AL      

    CALL DELAY      ; Wait so eyes can see it

    JMP LOOP_TOGGLE ; Repeat forever

; --- DELAY ---
DELAY:
    MOV CX, 0FFFFH  ; Long delay to make sure it's visible
WAIT:
    LOOP WAIT
    RET
