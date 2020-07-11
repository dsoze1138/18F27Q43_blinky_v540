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
;   -Wa,-a -Wl,-presetVec=0h,-phi_int_vec=08h,-plo_int_vec=18h,-pLowIsr_data=0h
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
;
WREG_save:      DS  1
STATUS_save:    DS  1
BSR_save:       DS  1
;
;   Low priority interrupt vector and handler
    PSECT   lo_int_vec,global,reloc=2,class=CODE,delta=1
;
LowIsrVec:
    movwf   WREG_save,c         ; We use the "old school" to
    movf    STATUS,w,c          ; save and restore context
    movwf   STATUS_save,c       ; because it is 2 instruction
    movf    BSR,w,c             ; words shorter than using
    movwf   BSR_save,c          ; the MOVFF opcode.
;
LowIsrHandler:
;
LowIsrExit:
    movf    BSR_save,w,c        ; Note: the pic-as always
    movwf   BSR,c               ; encodes the MOVFF as a
    movf    STATUS_save,w,c     ; 3-word MOVFFL opcode.
    movwf   STATUS,c            ; This is why we are using
    swapf   WREG_save,f,c       ; the "old school" method.
    swapf   WREG_save,w,c
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
;   Main application code
    PSECT   main_code,global,reloc=2,class=CODE,delta=1
;
main:
    bcf     TRISA,0,c     ; Make PORTA output bits
    bcf     LATA,0,c
    banksel ANSELA
    bcf     BANKMASK(ANSELA),0,b
;
AppLoop:
    btg     LATA,0,c
    goto    AppLoop
;
    END     resetVec
