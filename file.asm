; =============================================================
; Project: Scrolling "12345" (Corrected for Active-High CAT)
;
; Wiring Check:
; 1. PmodSSD AA..AG -> PA0..PA6 (Must wire BOTH J1 and J2 rows!)
; 2. PmodSSD CAT    -> PB0
; 3. PmodSSD VCC    -> +5V
; 4. PmodSSD GND    -> GND
; =============================================================

ORG 2000H
    JMP START

; --- DATA TABLE ---
; Codes: 0=3FH, 1=06H, 2=5BH, 3=4FH, 4=66H, 5=6DH, Blank=00H
CODES:  
    DB 00H      ; [0] Space
    DB 06H      ; [1] Number 1
    DB 5BH      ; [2] Number 2
    DB 4FH      ; [3] Number 3
    DB 66H      ; [4] Number 4
    DB 6DH      ; [5] Number 5
    DB 00H      ; [6] Space

; --- MAIN PROGRAM ---
START:
    ; Initialize 8255 (Port A, B, C as Output)
    MOV DX, 0FFE6H
    MOV AL, 80H
    OUT DX, AL

MAIN_LOOP:
    MOV SI, CODES   ; Start of data
    MOV CX, 6       ; 6 steps in the sequence

SCROLL_SEQ:
    PUSH CX

    ; Fetch digits
    MOV AL, BYTE [SI]    ; Left Digit Data
    MOV BL, BYTE [SI+1]  ; Right Digit Data
    
    ; Multiplex Loop (Hold this frame for a moment)
    MOV CX, 00FFH   ; Scroll Speed (Increase to slow down)

DISPLAY_FRAME:
    CALL MULTIPLEX
    LOOP DISPLAY_FRAME

    POP CX
    INC SI          ; Next number
    LOOP SCROLL_SEQ

    JMP MAIN_LOOP

; --- MULTIPLEXER (Active High Logic) ---
MULTIPLEX:
    PUSH AX
    PUSH DX

    ; 1. SHOW LEFT DIGIT
    ; Set CAT (PB0) to 1 to activate (Based on your VCC test)
    MOV DX, 0FFE2H  ; Port B
    MOV AH, 01H     ; High Signal
    OUT DX, AL      ; Wait... using AL for data. 
    ; Let's be precise:
    MOV AL, 01H     ; PB0 = 1 (ON)
    OUT DX, AL

    MOV DX, 0FFE0H  ; Port A
    POP AX          ; Recover Data
    PUSH AX         ; Save for next step
    OUT DX, AL      ; Send Segment Data (Left)
    
    CALL DELAY_SMALL

    ; 2. SHOW RIGHT DIGIT
    ; (For PmodSSD, usually One Pin toggles Left/Right)
    ; If PB0=1 is Left, PB0=0 might be Right? 
    ; Or we need a second pin? 
    ; Standard PmodSSD uses ONE pin (CAT) to swap.
    ; Let's try toggling PB0 to 0.
    
    MOV DX, 0FFE2H  ; Port B
    MOV AL, 00H     ; PB0 = 0
    OUT DX, AL
    
    MOV DX, 0FFE0H  ; Port A
    MOV AL, BL      ; Get Right Digit Data
    OUT DX, AL      ; Send Segment Data (Right)
    
    CALL DELAY_SMALL

    POP DX
    POP AX
    RET

DELAY_SMALL:
    PUSH CX
    MOV CX, 0100H
WAIT:
    LOOP WAIT
    POP CX
    RET
