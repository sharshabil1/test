; =============================================================
; SEGMENT FINDER TOOL
; -------------------------------------------------------------
; This program lights up ONE segment at a time.
; Watch your display and write down what you see.
;
; SEQUENCE:
; 1. Lights PA0 only -> Wait -> Lights PA1 only -> Wait...
; 2. Repeats forever.
; =============================================================

ORG 2000H
    JMP START

START:
    ; Configure 8255
    MOV DX, 0FFE6H
    MOV AL, 80H
    OUT DX, AL

    ; Force Right Display ON (since we know this works)
    MOV DX, 0FFE2H  ; Port B (CAT)
    MOV AL, 01H     ; High Signal
    OUT DX, AL

TEST_LOOP:
    ; --- TEST PA0 ---
    MOV DX, 0FFE0H
    MOV AL, 01H     ; Binary 0000 0001
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA1 ---
    MOV AL, 02H     ; Binary 0000 0010
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA2 ---
    MOV AL, 04H     ; Binary 0000 0100
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA3 ---
    MOV AL, 08H     ; Binary 0000 1000
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA4 ---
    MOV AL, 10H     ; Binary 0001 0000
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA5 ---
    MOV AL, 20H     ; Binary 0010 0000
    OUT DX, AL
    CALL LONG_DELAY

    ; --- TEST PA6 ---
    MOV AL, 40H     ; Binary 0100 0000
    OUT DX, AL
    CALL LONG_DELAY

    JMP TEST_LOOP

LONG_DELAY:
    MOV CX, 0FFFFH  ; Very slow delay
D1: LOOP D1
    MOV CX, 0FFFFH  ; Do it twice so you have time to see
D2: LOOP D2
    RET
