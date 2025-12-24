; =================================================================
; Project: Student ID Scroll on PmodSSD using 8255 PPI
; Objective: Scroll Student ID (222348835) on a Dual 7-Segment Display
;
; Hardware Interface:
;   - Port A (PA0-PA5): Segments A, B, C, D, E, F
;   - Port B (Any Pin): Segment G (Driven High)
;   - Port C (PC4):     Digit Selection (CAT)
; =================================================================

ORG 2000H
    JMP START

; --- SEGMENT DATA TABLE ---
; Format: DB (Port A Value), (Port B Value)
; Port A controls the outer ring (A-F).
; Port B controls the center bar (G).

CODES:
    DB 1BH, 0FFH    ; [0] '2'
    DB 1BH, 0FFH    ; [1] '2'
    DB 1BH, 0FFH    ; [2] '2'
    DB 0FH, 0FFH    ; [3] '3' 
    DB 26H, 0FFH    ; [4] '4' 
    DB 3FH, 0FFH    ; [5] '8'
    DB 3FH, 0FFH    ; [6] '8'
    DB 0FH, 0FFH    ; [7] '3'
    DB 2DH, 0FFH    ; [8] '5'
    DB 00H, 00H     ; [9] Space (Blank)

START:
    ; 1. CONFIGURE 8255 PPI
    ; Control Word: 10000000B (80H)
    ; Mode 0, All Ports (A, B, C) set as Output
    MOV DX, 0FFE6H   ; Control Register Address
    MOV AL, 80H      
    OUT DX, AL

MAIN_LOOP:
    MOV CX, 9        ; Number of scrolling steps
    MOV BP, 0        ; Digit Index Counter (0 to 8)

SCROLL_SEQUENCE:
    PUSH CX          

    ; Calculate Table Offset = Index * 2 (2 bytes per digit)
    MOV AX, BP
    ADD AX, BP       
    MOV DI, AX       ; DI holds the calculated offset

    ; --- SCROLL SPEED CONTROL ---
    ; Adjust CX value to change scroll speed (Higher = Slower)
    MOV CX, 01FFH   

MULTIPLEX_LOOP:
    CALL DISPLAY_PAIR
    LOOP MULTIPLEX_LOOP

    POP CX           
    INC BP           ; Move to next digit in sequence
    LOOP SCROLL_SEQUENCE
    
    JMP MAIN_LOOP    ; Repeat sequence indefinitely

; --- MULTIPLEXING ROUTINE ---
; Displays two digits rapidly to create persistence of vision.
DISPLAY_PAIR:
    PUSH AX
    PUSH DX
    PUSH SI

    ; Calculate memory pointer for current digit pair
    MOV SI, CODES
    ADD SI, DI       
    
    ; ======================================
    ; 1. DISPLAY RIGHT DIGIT
    ;    Logic: PC4 = 0 (Low) selects Right Digit
    ; ======================================
    
    ; A. Output Segment Data (A-F) to Port A
    MOV AL, BYTE [SI+2] 
    MOV DX, 0FFE0H      
    OUT DX, AL

    ; B. Output Segment G to Port B
    MOV AL, BYTE [SI+3] 
    MOV DX, 0FFE2H      
    OUT DX, AL

    ; C. Activate Digit (PC4 Low)
    MOV DX, 0FFE4H      
    MOV AL, 00H         
    OUT DX, AL
    
    CALL DELAY_MUX

    ; ======================================
    ; 2. DISPLAY LEFT DIGIT
    ;    Logic: PC4 = 1 (High) selects Left Digit
    ; ======================================

    ; A. Output Segment Data (A-F) to Port A
    MOV AL, BYTE [SI]   
    MOV DX, 0FFE0H      
    OUT DX, AL

    ; B. Output Segment G to Port B
    MOV AL, BYTE [SI+1] 
    MOV DX, 0FFE2H      
    OUT DX, AL

    ; C. Activate Digit (PC4 High)
    MOV DX, 0FFE4H      
    MOV AL, 10H         
    OUT DX, AL
    
    CALL DELAY_MUX

    ; Prevent Ghosting (Turn off Port A)
    MOV DX, 0FFE0H
    MOV AL, 00H
    OUT DX, AL
    
    POP SI
    POP DX
    POP AX
    RET

; --- DELAY SUBROUTINE ---
; Creates a short pause for stable multiplexing
DELAY_MUX:
    PUSH CX
    MOV CX, 0100H    
WAIT:
    LOOP WAIT
    POP CX
    RET
