; =================================================================
; Project: Student ID Scroll with BROKEN PA6 FIX
; Hardware Fix: 
;   - MOVE the wire for Segment G from PA6 -> PA7
;   - Keep all other segments (A-F) on PA0-PA5
;   - Keep CAT on PB0
; =================================================================

ORG 2000H
    JMP START

; --- NEW DATA TABLE (Remapped for PA7) ---
; Standard: g f e d c b a (Bit 6 is G)
; Fixed:    G f e d c b a (Bit 7 is G, Bit 6 is unused/0)
;
; 2: was 5BH (0101 1011) -> Remove bit 6 (0001 1011) -> Add bit 7 (1001 1011) = 9BH
; 4: was 66H (0110 0110) -> Remove bit 6 (0010 0110) -> Add bit 7 (1010 0110) = A6H
; 3: was 4FH (0100 1111) -> Remove bit 6 (0000 1111) -> Add bit 7 (1000 1111) = 8FH
; 8: was 7FH (0111 1111) -> Remove bit 6 (0011 1111) -> Add bit 7 (1011 1111) = BFH
; 5: was 6DH (0110 1101) -> Remove bit 6 (0010 1101) -> Add bit 7 (1010 1101) = ADH
; Space: 00H

CODES:
    DB 9BH      ; [0] '2'
    DB 9BH      ; [1] '2'
    DB 9BH      ; [2] '2'
    DB A6H      ; [3] '4'
    DB 8FH      ; [4] '3'
    DB BFH      ; [5] '8'
    DB BFH      ; [6] '8'
    DB 8FH      ; [7] '3'
    DB ADH      ; [8] '5'
    DB 00H      ; [9] Space

START:
    ; Initialize 8255 (All Outputs)
    MOV DX, 0FFE6H
    MOV AL, 80H
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Point to ID numbers
    MOV CX, 9       ; 9 digits in ID

SCROLL_SEQUENCE:
    PUSH CX

    ; Load pair
    MOV AL, BYTE [SI]
    MOV BL, BYTE [SI+1]

    ; --- SCROLL SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX
    INC SI
    LOOP SCROLL_SEQUENCE
    JMP MAIN_LOOP

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX

    ; 1. DISPLAY RIGHT (PB0 = 1)
    MOV DX, 0FFE2H   ; Port B
    MOV AL, 01H      ; Signal High
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A
    MOV AL, BL       ; Right Digit Data
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; 2. DISPLAY LEFT (PB0 = 0)
    MOV DX, 0FFE2H   ; Port B
    MOV AL, 00H      ; Signal Low
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A
    POP AX           ; Restore AL (Left Data)
    PUSH AX          
    OUT DX, AL       ; Left Digit Data
    
    CALL DELAY_MUX

    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0150H    ; Balanced delay
WAIT:
    LOOP WAIT
    POP CX
    RET
