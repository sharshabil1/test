; =================================================================
; Project: Student ID Scroll (CAT ON PB0 VERSION)
;
; NEW WIRING:
;   PA0-PA5: Segments A-F (Unchanged)
;   PB0:     CAT (Digit Select) -> 0=Right, 1=Left
;   PB1-PB7: Segment G (We drive these High to light G)
;
; LOGIC CHANGE:
;   We now mix Data (G) and Control (CAT) on Port B.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Stores only Segment A-F codes (Port A).
; G and CAT are handled dynamically in the logic below.
CODES:
    DB 1BH      ; [0] '2'
    DB 1BH      ; [1] '2'
    DB 1BH      ; [2] '2'
    DB 0FH      ; [3] '3'
    DB 26H      ; [4] '4'
    DB 3FH      ; [5] '8'
    DB 3FH      ; [6] '8'
    DB 0FH      ; [7] '3'
    DB 2DH      ; [8] '5'
    DB 00H      ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Start of ID
    MOV CX, 9        ; 9 steps

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair
    MOV AL, [SI]     ; Left Digit Data
    MOV BL, [SI+1]   ; Right Digit Data

    ; --- SPEED ---
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

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (CAT PB0 = 0)
    ; ======================================

    ; A. Port A (Segments A-F)
    MOV DX, 0FFE0H   ; Port A
    MOV AL, BL       ; Load Right Data
    OUT DX, AL       

    ; B. Port B (G + CAT Low)
    ; Logic: If Data is not Space (00H), turn G ON (Bits 1-7 High).
    ;        Keep Bit 0 LOW for CAT.
    MOV DX, 0FFE2H   ; Port B
    CMP BL, 00H      ; Is it a space?
    JZ  NO_G_RIGHT   
    
    ; G is ON, CAT is LOW (Right) -> Binary 1111 1110 = FEH
    MOV AL, 0FEH     
    JMP OUT_RIGHT
    
NO_G_RIGHT:
    ; G is OFF, CAT is LOW -> 00H
    MOV AL, 00H      

OUT_RIGHT:
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PB0 = 1)
    ; ======================================

    ; A. Port A (Segments A-F)
    MOV DX, 0FFE0H   ; Port A
    POP AX           ; Restore Left Data (Original AL)
    PUSH AX          ; Save it back
    OUT DX, AL       

    ; B. Port B (G + CAT High)
    ; Logic: If Data is not Space, turn G ON (Bits 1-7 High).
    ;        Keep Bit 0 HIGH for CAT.
    MOV DX, 0FFE2H   ; Port B
    CMP AL, 00H      ; Is it a space?
    JZ  NO_G_LEFT
    
    ; G is ON, CAT is HIGH (Left) -> Binary 1111 1111 = FFH
    MOV AL, 0FFH     
    JMP OUT_LEFT

NO_G_LEFT:
    ; G is OFF, CAT is HIGH -> Binary 0000 0001 = 01H
    MOV AL, 01H      

OUT_LEFT:
    OUT DX, AL       

    CALL DELAY_MUX

    ; Ghosting Fix (Turn off Segments)
    MOV DX, 0FFE0H
    MOV AL, 00H
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
