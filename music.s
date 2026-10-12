; WiiShop6502
; Written by meowcat767 - 2026

NOTE_COUNT = 6

.segment "HEADER"
.byte $4E, $45, $53, $1A
.byte $02               ; 32 KB PRG ROM
.byte $00               ; CHR RAM
.byte $00, $00          ; Mapper 0
.byte $00, $00, $00, $00, $00, $00, $00, $00 ; reserved header bytes

.segment "ZEROPAGE"
note_index: .res 1
note_ticks: .res 1

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$40
    stx $4017           ; disable APU frame IRQ
    ldx #$FF
    txs
    inx
    stx $2000           ; disable NMI
    stx $2001           ; disable rendering
    stx $4010          ; disable DMC IRQ
    stx $4015          ; disable APU channels
    ; wait for PPU startup to settle
    bit $2002

@wait1:
    bit $2002
    bpl @wait1
@wait2:
    bit $2002
    bpl @wait2
    ; start at the first note
    lda #$00
    sta note_index
    jsr load_note

    ; advance the music once per PPU frame

frame_loop:
@wait_frame:
    bit $2002
    bpl @wait_frame
    dec note_ticks
    bne frame_loop
    ; advance to the next note
    inc note_index
    lda note_index
    cmp #NOTE_COUNT
    bcc @index_ok
    lda #$00
    sta note_index
@index_ok:
    jsr load_note
    jmp frame_loop
.endproc

; load the current note's pitch and duration
.proc load_note
    ldx note_index
    lda note_durations,x
    sta note_ticks
    lda note_lo,x
    ; timer value zero means a rest!
    beq @rest
    ; enable pulse channel 1
    lda #$01
    sta $4015
    ; constant volume, 50% duty cycle
    lda #$BF
    sta $4000
    ; set the 11-bit pulse timer
    ldx note_index
    lda note_lo,x
    sta $4002
    lda note_hi,x
    and #$07
    sta $4003
    rts

@rest:
    lda #$00
    sta $4015
    rts
.endproc

; test melody
; REMOVE ME AFTER TEST!

note_lo:
    .byte $FE       ; A4
    .byte $D5       ; C5
    .byte $BE       ; D5
    .byte $9F       ; F5
    .byte $FE       ; A4
    .byte $00       ; Rest

note_hi:
    .byte $00, $00, $00, $00, $00, $00

note_durations:
    .byte 18, 18, 18, 36, 18, 18

.segment "VECTORS"
.word reset, reset, reset

.segment "CHARS"
.res 8192, $00
