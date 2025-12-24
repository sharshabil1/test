; =================================================================
; Project: Student ID Scroll (VISUAL CORRECTION)
;
; DIAGNOSIS:
;   - PA7/PA6 were swapped (B <-> F)
;   - PA5/PA2 were swapped (C <-> E)
;   This fixes the "Upside Down 4" and "Flipped 3" (E shape).
;
; NEW MAPPING:
;   PA0=A, PA2=E, PA3=D, PA4=CAT, PA5=C, PA6=B, PA7=F
;   PB0=G
; =================================================================

ORG 2000H
    JMP START

; --- RECALCULATED CODES ---
; '2' (A,B,D,E,G) -> Bits 0,6,3,2 -> 4DH
; '3' (A,B,C,D,G) -> Bits 0,6,5,3 -> 69H
; '4' (F,B,C,G)   -> Bits 7,6,5   -> E0H
; '8' (All)       -> Bits 0,2,3,5,6,7 -> EDH
; '5' (A,F,C,D,G) -> Bits 0,7,5,3 -> A9H
; Space           -> 00H

CODES:
    DB 4DH      ; [0] '2'
    DB 4DH      ; [1] '2'
    DB 4DH      ; [2] '2'
    DB 69H      ; [3] '3' (Fixed shape)
    DB 0E0H     ; [4] '4' (Fixed orientation)
    DB 0EDH     ; [5] '8'
    DB 0EDH     ; [6] '8'
    DB 69H      ; [7] '3'
    DB 0A9H     ; [8] '5'
    DB 00H      ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES    ; Point to start of ID
    MOV CX, 9        ; 9 digits to scroll

SCROLL_SEQUENCE:
    PUSH CX          

    ; Load pair
    MOV AL, [SI]     ; Left
    MOV BL, [SI+1]   ; Right

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

    ; --------------------------------------
    ; 1. DISPLAY RIGHT DIGIT (CAT=0)
    ; --------------------------------------
    
    ; Segment G (Port B)
    MOV DX, 0FFE2H   
    CMP BL, 00H      ; Check for Space
    JZ  NO_G_RIGHT
    MOV AH, 01H      ; G ON
    JMP OUT_G_RIGHT
NO_G_RIGHT:
    MOV AH, 00H      ; G OFF
OUT_G_RIGHT:
    MOV AL, AH
    OUT DX, AL       

    ; Port A Segments
    MOV DX, 0FFE0H   
    MOV AL, BL       
    AND AL, 0EFH     ; CAT=0
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; --------------------------------------
    ; 2. DISPLAY LEFT DIGIT (CAT=1)
    ; --------------------------------------

    ; Segment G (Port B)
    POP DX           
    POP AX           ; Restore Left Data
    PUSH AX
    PUSH DX
    
    MOV DX, 0FFE2H   
    CMP AL, 00H
    JZ  NO_G_LEFT
    MOV AH, 01H      ; G ON
    JMP OUT_G_LEFT
NO_G_LEFT:
    MOV AH, 00H      ; G OFF
OUT_G_LEFT:
    PUSH AX          
    MOV AL, AH
    OUT DX, AL       
    POP AX           

    ; Port A Segments
    MOV DX, 0FFE0H   
    OR  AL, 10H      ; CAT=1
    OUT DX, AL       
    
    CALL DELAY_MUX

    ; Ghosting Fix
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
