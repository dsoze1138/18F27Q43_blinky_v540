; File:     main.S
; Target:   PIC18F27Q43
; Author:   dan1138
; Date:     2020-07-11
; Compiler: pic-as(v2.20)
; IDE:      MPLABX v5.40
;
; Description:
;
;   Toggle PORTA bit 0
;
; Add this line in the project properties box, pic-as Global Options -> Additional options:
;   -Wa,-a -Wl,-presetVec=0h,-phi_int_vec=08h,-plo_int_vec=18h
;
    PROCESSOR   18F27Q43
    PAGEWIDTH   132
    RADIX       dec
;
#include <xc.inc>
;
 config FEXTOSC = OFF, RSTOSC = HFINTOSC_64MHZ, CLKOUTEN = OFF
 config PR1WAY = OFF, CSWEN = ON, FCMEN = OFF, MCLRE = EXTMCLR
 config PWRTS = PWRT_OFF, MVECEN = OFF, IVT1WAY = OFF
 config LPBOREN = OFF, BOREN = OFF, BORV = VBOR_1P9
 config ZCD = OFF, PPS1WAY = OFF, STVREN = ON, LVP = ON
 config XINST = OFF, WDTCPS = WDTCPS_31, WDTE = OFF
 config WDTCWS = WDTCWS_7, WDTCCS = SC, BBSIZE = BBSIZE_512
 config BBEN = OFF, SAFEN = OFF
 config WRTB = OFF, WRTC = OFF, WRTD = OFF
 config WRTSAF = OFF, WRTAPP = OFF, CP = OFF
;
#define FCY (16000000)
;
;   Reset vector
    PSECT   resetVec,global,reloc=2,class=CODE,delta=1
;
resetVec:
    goto    Start
;
;   High priority interrupt vector
    PSECT   hi_int_vec,global,reloc=2,class=CODE,delta=1
;
    goto    HighIsrHandler
;
;   Data space use by low priority interrupt handler to save context
    PSECT   LowIsr_data,global,class=COMRAM,space=1,delta=1,lowdata,noexec
;
    GLOBAL  WREG_save,STATUS_save,BSR_save
    GLOBAL  DelayCycles
;
WREG_save:      DS  1
STATUS_save:    DS  1
BSR_save:       DS  1
DelayCycles:    DS  4
;
;   Low priority interrupt vector and handler
    PSECT   lo_int_vec,global,reloc=2,class=CODE,delta=1
;
LowIsrVec:
    movwf   BANKMASK(WREG_save),c   ; We use the "old school" to
    movf    STATUS,w,c              ; save and restore context
    movwf   BANKMASK(STATUS_save),c ; because it is 2 instruction
    movf    BSR,w,c                 ; words shorter than using
    movwf   BANKMASK(BSR_save),c    ; the MOVFF opcode.
;
LowIsrHandler:
;
LowIsrExit:
    movf    BANKMASK(BSR_save),w,c  ; Note: the pic-as always
    movwf   BSR,c                   ; encodes the MOVFF as a
    movf    BANKMASK(STATUS_save),w,c ; 3-word MOVFFL opcode.
    movwf   STATUS,c                ; This is why we are using
    swapf   BANKMASK(WREG_save),f,c ; the "old school" method.
    swapf   BANKMASK(WREG_save),w,c
    retfie  0   ; Return from interrupt
;
;   High priority interrupt handler
    PSECT   HighIsr_code,global,reloc=2,class=CODE,delta=1
;
HighIsrHandler:
    retfie  1   ; Fast return from interrupt
;
;   Startup code used at power on reset
    PSECT   start_code,global,reloc=2,class=CODE,delta=1
;
Start:
    bcf     INTCON0,INTCON0_GIEH_POSITION,c   ; Disable all interrupts
    bcf     INTCON0,INTCON0_GIEL_POSITION,c
    bsf     INTCON0,INTCON0_IPEN_POSITION,c   ; Enable interrupt priority
;
;
    bsf     INTCON0,INTCON0_GIEL_POSITION,c
    bsf     INTCON0,INTCON0_GIEH_POSITION,c ; Enable all interrupts
    goto    main
;
; Cycle accurate parametric delay
; 
; Notes: 
;
;  With a 64MHz oscillator the range and
;  resolution of this delay function is:
;
;    Minimum:    x.xx microseconds
;    Maximum: xxxx.xxxxxxx seconds
;    Resolution: 0.xx microseconds
Delay_Plus_25_Cycles:
        clrf  PCLATU,c
        movlw HIGH(Delay_Plus_25_Cycles_Nops)
        movwf PCLATH,c

Delay_Plus_25_Cycles_Loop:
        movlw   -12
        addwf   BANKMASK(DelayCycles)+0,f,c
        movlw   -1
        btfss   STATUS,0,c
        addwf   BANKMASK(DelayCycles)+1,f,c
        btfss   STATUS,0,c
        addwf   BANKMASK(DelayCycles)+2,f,c
        btfss   STATUS,0,c
        addwf   BANKMASK(DelayCycles)+3,f,c
        btfsc   STATUS,0,c
        bra     Delay_Plus_25_Cycles_Loop

        comf    BANKMASK(DelayCycles)+0,f,c
        rlcf    BANKMASK(DelayCycles)+0,w,c
        addlw   LOW(Delay_Plus_25_Cycles_Nops)
        btfsc   STATUS,0,c
        incf    PCLATH,f,c
        movwf   PCL,c       ; MPLABX v5.40 simulator broken, this is a 2 cycle instruction.
Delay_Plus_25_Cycles_Nops:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        return
;
;   Main application code
    PSECT   main_code,global,reloc=2,class=CODE,delta=1
;
main:
    bcf     TRISA,0,c     ; Make PORTA output bits
    bcf     LATA,0,c
    banksel ANSELA
    bcf     BANKMASK(ANSELA),0,b
;
#define CYCLES_IN_HALF_SECOND ((FCY/2)-25)
;
AppLoop:
    movlw   CYCLES_IN_HALF_SECOND >> 24
    movwf   BANKMASK(DelayCycles)+3,c
    movlw   CYCLES_IN_HALF_SECOND >> 16
    movwf   BANKMASK(DelayCycles)+2,c
    movlw   CYCLES_IN_HALF_SECOND >> 8
    movwf   BANKMASK(DelayCycles)+1,c
    movlw   CYCLES_IN_HALF_SECOND 
    movwf   BANKMASK(DelayCycles),c
    call    Delay_Plus_25_Cycles
    btg     LATA,0,c
    goto    AppLoop
;
    END     resetVec
