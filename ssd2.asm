; =================================================================
; Project: Student ID Scroll (CORRECTED INTERFACE)
; Fixed based on 'ssd.asm' working logic:
;   1. Reverted Segment Codes to STANDARD (A-G on PA0-PA6).
;   2. Fixed Multiplexing: Uses PB0 for Right, PB1 for Left.
;      (00H was turning the display OFF).
; =================================================================

ORG 2000H
    JMP START

; --- STANDARD DATA TABLE (PA0-PA6) ---
; Reverted to original values. 
; Format: g f e d c b a
; '2' = 5BH (0101 1011)
; '4' = 66H (0110 0110)
; '3' = 4FH (0100 1111)
; '8' = 7FH (0111 1111)
; '5' = 6DH (0110 1101)
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
    DB 00H      ; [9] Space

START:
    ; 1. CONFIGURE 8255 (Match ssd.asm)
    ; Port A = Output (Segments)
    ; Port B = Output (Digit Select)
    MOV DX, 0FFE6H   ; Control Register
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          ; Save outer loop counter

    ; Load the pair of digits to display
    MOV AL, [SI]     ; Load Left Data (current)
    MOV BL, [SI+1]   ; Load Right Data (next)

    ; --- SCROLL SPEED DURATION ---
    ; Higher value = Slower scroll
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           ; Restore outer loop counter
    INC SI           ; Move to next digit
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    ; Restart scroll from beginning

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    ; Input: AL has Left Data, BL has Right Data
    PUSH AX
    PUSH DX

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT (PB0 Active)
    ; --------------------------------------
    MOV DX, 0FFE2H   ; Port B (Control)
    MOV AL, 01H      ; PB0 = 1 (Enable Right)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A (Segments)
    MOV AL, BL       ; Send Right Data
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT (PB1 Active)
    ; --------------------------------------
    ; In ssd.asm, 01H turned it ON. 00H likely turns it OFF.
    ; We use PB1 (02H) for the other digit.
    MOV DX, 0FFE2H   ; Port B (Control)
    MOV AL, 02H      ; PB1 = 1 (Enable Left)
    OUT DX, AL

    MOV DX, 0FFE0H   ; Port A (Segments)
    POP AX           ; Restore AL (Left Data) from Stack
    PUSH AX          ; Save it back for safety
    OUT DX, AL       ; Send Left Data
    
    CALL DELAY_MUX

    ; Turn off both to prevent ghosting (Optional but recommended)
    MOV DX, 0FFE2H
    MOV AL, 00H
    OUT DX, AL

    POP DX
    POP AX
    RET

DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    ; Short delay for multiplexing
WAIT:
    LOOP WAIT
    POP CX
    RET
