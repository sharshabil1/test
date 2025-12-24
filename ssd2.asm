; =================================================================
; Project: Student ID Scroll (LATEST WIRING)
;
; MAPPING:
;   PA0=A, PA1=B(AP), PA2=C, PA3=D, PA4=E, PA5=F
;   PB6=G
;   PC4=CAT
;
; LOGIC:
;   - Port A handles the outer circle of the digit (A-F).
;   - Port B handles the middle bar (G).
;   - Port C switches between Left/Right digits.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Format: DB (Port A Value), (Port B Value)
;
; Calculations:
; '2' (A,B,D,E,G) -> PA: Bits 0,1,3,4 = 1BH.  PB: Bit 6 = 40H.
; '3' (A,B,C,D,G) -> PA: Bits 0,1,2,3 = 0FH.  PB: Bit 6 = 40H.
; '4' (B,C,F,G)   -> PA: Bits 1,2,5   = 26H.  PB: Bit 6 = 40H.
; '8' (All)       -> PA: Bits 0-5     = 3FH.  PB: Bit 6 = 40H.
; '5' (A,C,D,F,G) -> PA: Bits 0,2,3,5 = 2DH.  PB: Bit 6 = 40H.
; Space           -> PA: 00H.         PB: 00H.

CODES:
    DB 1BH, 40H     ; [0] '2'
    DB 1BH, 40H     ; [1] '2'
    DB 1BH, 40H     ; [2] '2'
    
    DB 0FH, 40H     ; [3] '3' (Swapped to correct order)
    DB 26H, 40H     ; [4] '4' 

    DB 3FH, 40H     ; [5] '8'
    DB 3FH, 40H     ; [6] '8'
    DB 0FH, 40H     ; [7] '3'
    DB 2DH, 40H     ; [8] '5'
    DB 00H, 00H     ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    ; All Ports Output (Mode 0)
    MOV DX, 0FFE6H   
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV SI, 0        ; Digit Index (0-9)
    MOV CX, 9        ; Scroll Steps

SCROLL_SEQUENCE:
    PUSH CX          

    ; Calculate memory offset: SI * 2
    MOV DI, SI
    ADD DI, SI       

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
    PUSH DI

    ; DI points to Left Digit. DI+2 points to Right Digit.

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (PC4 = 0)
    ; ======================================
    
    ; A. Segments A-F (Port A)
    MOV AL, CODES[DI+2] ; Load Right Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, CODES[DI+3] ; Load Right Digit Port B
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = Low)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 00H         ; Bit 4 = 0
    OUT DX, AL
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (PC4 = 1)
    ; ======================================

    ; A. Segments A-F (Port A)
    MOV AL, CODES[DI]   ; Load Left Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, CODES[DI+1] ; Load Left Digit Port B
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = High)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 10H         ; Bit 4 = 1
    OUT DX, AL
    
    CALL DELAY_MUX

    ; Turn off to prevent ghosting
    MOV DX, 0FFE0H
    MOV AL, 00H
    OUT DX, AL
    
    POP DI
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
