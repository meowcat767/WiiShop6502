; Wii Shop Channel theme for the NES (6502)

.segment "HEADER"
.byte $4E, $45, $53, $1A
.byte $02               ; 32 KB PRG ROM
.byte $00               ; CHR RAM
.byte $00, $00          ; Mapper 0
.byte $00, $00, $00, $00, $00, $00, $00, $00

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$40
    stx $4017            ; Disable APU frame IRQ
    ldx #$FF
    txs
    inx
    stx $2000            ; Disable NMI
    stx $2001            ; Disable rendering
    stx $4010            ; Disable DMC IRQ

    bit $2002
@wait_vblank1:
    bit $2002
    bpl @wait_vblank1
@wait_vblank2:
    bit $2002
    bpl @wait_vblank2

    ldx #<music_data_untitled
    ldy #>music_data_untitled
    lda #1               ; NTSC
    jsr famistudio_init
    lda #0               ; Song index
    jsr famistudio_music_play

@frame:
@wait_frame:
    bit $2002
    bpl @wait_frame
    jsr famistudio_update
    jmp @frame
.endproc

.include "song.s"
.include "famistudio_ca65.s"

.segment "VECTORS"
.word reset, reset, reset

.segment "CHARS"
.res 8192, $00
