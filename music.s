; WiiShop6502
; Written by meowcat767 - 2026

.segment "HEADER"
.byte $4E, $45, $53, $1A ; iNES magic
.byte $02 ; PRG ROM size
.byte $00 ; CHR RAM
.byte $00, $00 ; Mapper 0
.res 8, $00

.segment "ZEROPAGE"
note_timer: res 1

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$40
    stx $4017               ; DISABLE FRAME IRQ
    txs 
    inx                     ; X = 0

    stx $2000               ; Disable NMI
    stx $2001               ; Disable rendering
    stx $4010               ; Disable DMC IRQ
    stx $4015               ; Disable APU channels

    ; wait for ppu startup
    bit $2002

wait_vblank:
    bit $2002
    bpl wait_vblank

    ; enable pulse channel 1
    lda #$01
    sta $4015

    ; duty cycle and constant vol
    lda #$BF
    sta $4000

    ; set pulse timer for a tone
    lda #$FD
    sta $4002
    lda #$08
    sta $4003

forever:
    jmp forever
.endproc

.segment "VECTORS"
.word reset, reset, reset

.segment "CHARS"
.res 8192, $00