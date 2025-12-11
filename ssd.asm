; =================================================================
; FINAL HARDWARE TEST
; Objective: Light up "88" on the PmodSSD
;
; =================================================================

ORG 2000H
    JMP START

START:
    ; 1. CONFIGURE 8255 (All Outputs)
    MOV DX, 0FFE6H   ; Control Register
    MOV AL, 80H      ; Mode 0, All Out
    OUT DX, AL

LOOP_CHECK:
    ; 2. ACTIVATE DIGIT SELECT (CAT = HIGH)
    ; Your previous test showed VCC (High) turns it on.
    ; So we send '1' to PB0.
    MOV DX, 0FFE2H   ; Port B Address
    MOV AL, 01H      ; PB0 = 1
    OUT DX, AL

    ; 3. ACTIVATE SEGMENTS (Active LOW or HIGH?)
    ; PmodSSD is usually active High segments if CAT is common cathode.
    ; Let's try sending ALL 1s (FF) first.
    MOV DX, 0FFE0H   ; Port A Address
    MOV AL, 0FFH     ; All Segments High
    OUT DX, AL

    ; If the display is inverted (Common Anode), try 00H instead.
    ; Use a delay loop to keep it stable
    MOV CX, 0FFFFH
DELAY:
    LOOP DELAY

    JMP LOOP_CHECK
