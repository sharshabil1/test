; =================================================================
; Project: Student ID Scroll (SYNTAX MATCHING ssd.asm)
;
; WIRING MAPPING:
;   PA0=AA, PA1=AP(B), PA2=AC, PA3=AD, PA4=AE, PA5=AF
;   PB6=AG
;   PC4=CAT
;
; FIX: 
;   1. Used 'MOV SI, CODES' (Address load) instead of LEA/OFFSET.
;   2. Used 'BYTE [SI]' syntax to match your working ssd.asm.
; =================================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Format: DB (Port A Value), (Port B Value)
CODES:
    DB 1BH, 40H     ; [0] '2'
    DB 1BH, 40H     ; [1] '2'
    DB 1BH, 40H     ; [2] '2'
    
    DB 0FH, 40H     ; [3] '3' 
    DB 26H, 40H     ; [4] '4' 

    DB 3FH, 40H     ; [5] '8'
    DB 3FH, 40H     ; [6] '8'
    DB 0FH, 40H     ; [7] '3'
    DB 2DH, 40H     ; [8] '5'
    DB 00H, 00H     ; [9] Space

START:
    ; 1. CONFIGURE 8255 
    MOV DX, 0FFE6H   
    MOV AL, 80H      ; Mode 0, All Output
    OUT DX, AL

MAIN_LOOP:
    MOV CX, 9        ; Scroll Steps
    MOV BP, 0        ; Use BP as our Digit Index Counter (0 to 8)

SCROLL_SEQUENCE:
    PUSH CX          

    ; Calculate array offset = Index * 2
    ; We store this in DI to use later
    MOV AX, BP
    ADD AX, BP       ; AX = BP * 2
    MOV DI, AX       ; DI = Offset

    ; --- SCROLL SPEED ---
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC BP           ; Next Digit Index
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    

; --- MULTIPLEXING ROUTINE ---
DISPLAY_PAIR:
    PUSH AX
    PUSH DX
    PUSH SI

    ; 1. Load Address of CODES into SI (Like ssd.asm)
    MOV SI, CODES
    
    ; 2. Add the current offset (DI) to point to the correct pair
    ADD SI, DI       
    
    ; Now SI points to the Left Digit Data.
    ; SI+2 points to the Right Digit Data.

    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT (PC4 = 0)
    ;    Data is at [SI + 2] and [SI + 3]
    ; ======================================
    
    ; A. Segments A-F (Port A)
    MOV AL, BYTE [SI+2] ; Load Right Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, BYTE [SI+3] ; Load Right Digit Port B
    MOV DX, 0FFE2H      ; Port B Address
    OUT DX, AL

    ; C. Activate Digit (PC4 = Low)
    MOV DX, 0FFE4H      ; Port C Address
    MOV AL, 00H         ; Bit 4 = 0
    OUT DX, AL
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT (PC4 = 1)
    ;    Data is at [SI] and [SI + 1]
    ; ======================================

    ; A. Segments A-F (Port A)
    MOV AL, BYTE [SI]   ; Load Left Digit Port A
    MOV DX, 0FFE0H      ; Port A Address
    OUT DX, AL

    ; B. Segment G (Port B)
    MOV AL, BYTE [SI+1] ; Load Left Digit Port B
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
    
    POP SI
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
