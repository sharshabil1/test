; =================================================================
; Project: Student ID Scroll (FINAL SIMPLE VERSION)
;
; HARDWARE MAPPING:
;   PA0=A, PA1=B, PA2=C, PA3=D, PA4=E, PA5=F
;   Port B: Segment G (We send FFH to light it up)
;   Port C: CAT (PC4) -> Toggle this to switch digits
;
; LOGIC:
;   - We use the simple 'INC SI' scrolling method from your reference.
;   - We output to Port A (Segments), Port B (G), and Port C (CAT).
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Only contains Port A segment codes (A-F).
; G is handled automatically in the code (Turned ON if digit is not Space).
;
; '2' (A,B,D,E) -> Bits 0,1,3,4 = 1BH
; '3' (A,B,C,D) -> Bits 0,1,2,3 = 0FH
; '4' (B,C,F)   -> Bits 1,2,5   = 26H
; '8' (All A-F) -> Bits 0-5     = 3FH
; '5' (A,C,D,F) -> Bits 0,2,3,5 = 2DH
; Space         -> 00H

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
    ; 1. CONFIGURE 8255 (All Outputs)
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
    INC SI           ; Move to next digit
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    ; AL = Left Data (Port A)
    ; BL = Right Data (Port A)
    PUSH AX
    PUSH DX

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (CAT PC4 = 0)
    ; ======================================
    
    ; A. Handle Segment G (Port B)
    MOV DX, 0FFE2H   ; Port B Address
    CMP BL, 00H      ; Is Right Digit a Space?
    JZ  NO_G_RIGHT
    MOV AH, 0FFH     ; G ON (Send FFH to be safe)
    JMP OUT_G_RIGHT
NO_G_RIGHT:
    MOV AH, 00H      ; G OFF
OUT_G_RIGHT:
    PUSH AX          ; Save AL (Left Data)
    MOV AL, AH
    OUT DX, AL       ; Send G to Port B
    POP AX           ; Restore AL

    ; B. Handle Port A (Segments A-F)
    MOV DX, 0FFE0H   ; Port A Address
    PUSH AX          ; Save AL
    MOV AL, BL       ; Move Right Data to AL
    OUT DX, AL       ; Send to Port A
    POP AX           ; Restore AL

    ; C. Handle CAT (Port C) -> LOW for Right
    MOV DX, 0FFE4H   ; Port C Address
    PUSH AX
    MOV AL, 00H      ; PC4 = 0
    OUT DX, AL
    POP AX
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (CAT PC4 = 1)
    ; ======================================

    ; A. Handle Segment G (Port B)
    MOV DX, 0FFE2H   ; Port B Address
    CMP AL, 00H      ; Is Left Digit a Space?
    JZ  NO_G_LEFT
    MOV AH, 0FFH     ; G ON
    JMP OUT_G_LEFT
NO_G_LEFT:
    MOV AH, 00H      ; G OFF
OUT_G_LEFT:
    PUSH AX          ; Save AL
    MOV AL, AH
    OUT DX, AL       ; Send G to Port B
    POP AX           ; Restore AL

    ; B. Handle Port A (Segments A-F)
    MOV DX, 0FFE0H   ; Port A Address
    OUT DX, AL       ; Send Left Data to Port A (AL already has it)

    ; C. Handle CAT (Port C) -> HIGH for Left
    MOV DX, 0FFE4H   ; Port C Address
    PUSH AX
    MOV AL, 10H      ; PC4 = 1 (Bit 4 High)
    OUT DX, AL
    POP AX
    
    CALL DELAY_MUX

    ; Turn off to prevent ghosting
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
