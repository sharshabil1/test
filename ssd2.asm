; =================================================================
; Project: Student ID Scroll (CUSTOM WIRING)
;
; HARDWARE MAPPING:
;   Port A: B(7), F(6), E(5), CAT(4), D(3), C(2), X(1), A(0)
;   Port B: G(0)
;
;   Note: CAT is on PA4. We must toggle PA4 to switch digits.
;         Segment G is on PB0. We must turn PB0 ON for digits.
; =================================================================

ORG 2000H
    JMP START

; --- SCRAMBLED DATA TABLE ---
; Calculated for your specific wiring:
; '2' (A,B,D,E,G) -> Port A: 0A9H, Port B: 01H
; '4' (B,C,F,G)   -> Port A: 0C4H, Port B: 01H
; '3' (A,B,C,D,G) -> Port A: 8DH,  Port B: 01H
; '8' (All)       -> Port A: 0EDH, Port B: 01H
; '5' (A,C,D,F,G) -> Port A: 4DH,  Port B: 01H
; Space           -> Port A: 00H,  Port B: 00H

CODES:
    DB 0A9H     ; [0] '2'
    DB 0A9H     ; [1] '2'
    DB 0A9H     ; [2] '2'
    DB 0C4H     ; [3] '4'
    DB 8DH      ; [4] '3'
    DB 0EDH     ; [5] '8'
    DB 0EDH     ; [6] '8'
    DB 8DH      ; [7] '3'
    DB 4DH      ; [8] '5'
    DB 00H      ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    ; Port A = Output (Segments + CAT)
    ; Port B = Output (Segment G)
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          ; Save outer loop counter

    ; Load the pair of digits
    MOV AL, [SI]     ; Load Left Digit Data
    MOV BL, [SI+1]   ; Load Right Digit Data

    ; --- SCROLL SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           ; Restore outer loop counter
    INC SI           ; Move to next digit index
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    ; AL = Left Data (Port A Base)
    ; BL = Right Data (Port A Base)
    PUSH AX
    PUSH DX

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT
    ;    (Assume CAT=0 selects Right. If inverted, swap logic)
    ; --------------------------------------
    
    ; A. Handle Segment G (Port B)
    ; Check if BL is 0 (Space). If so, G=0. Else G=1.
    MOV DX, 0FFE2H   ; Port B
    CMP BL, 00H
    JZ  NO_G_RIGHT
    MOV AH, 01H      ; G ON
    JMP OUT_G_RIGHT
NO_G_RIGHT:
    MOV AH, 00H      ; G OFF
OUT_G_RIGHT:
    MOV AL, AH
    OUT DX, AL       ; Send to Port B

    ; B. Handle Port A (Segments + CAT)
    ; We want CAT (PA4) = 0 for Right Digit
    MOV DX, 0FFE0H   ; Port A
    MOV AL, BL       ; Get segment data
    AND AL, 0EFH     ; Force Bit 4 (CAT) to 0
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT
    ;    (Assume CAT=1 selects Left)
    ; --------------------------------------

    ; A. Handle Segment G (Port B)
    POP DX           ; Fix stack momentarily
    POP AX           ; Retrieve original AL (Left Data)
    PUSH AX
    PUSH DX
    
    MOV DX, 0FFE2H   ; Port B
    CMP AL, 00H
    JZ  NO_G_LEFT
    MOV AH, 01H      ; G ON
    JMP OUT_G_LEFT
NO_G_LEFT:
    MOV AH, 00H      ; G OFF
OUT_G_LEFT:
    PUSH AX          ; Save AL (Left Data) again
    MOV AL, AH
    OUT DX, AL       ; Send to Port B
    POP AX           ; Restore AL

    ; B. Handle Port A (Segments + CAT)
    ; We want CAT (PA4) = 1 for Left Digit
    MOV DX, 0FFE0H   ; Port A
    OR  AL, 10H      ; Force Bit 4 (CAT) to 1
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; Optional: Turn off bits to prevent ghosting
    MOV DX, 0FFE0H
    MOV AL, 00H      ; All segments OFF (and CAT=0)
    OUT DX, AL

    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    
WAIT:
    LOOP WAIT
    POP CX
    RET
