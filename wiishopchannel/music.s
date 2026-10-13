; Wii Shop for NES - written by meowcat767 - 2026
.segment "HEADER"
.byte $4E, $45, $53, $1A
.byte $02               ; 32 KB PRG ROM
.byte $01               ; 1x 8KB CHR ROM (Instead of CHR RAM, using static ROM)
.byte $00, $00          ; Mapper 0 (NROM)
.byte $00, $00, $00, $00, $00, $00, $00, $00

; --- PPU Hardware Register Aliases ---
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

.segment "ZP": zeropage
last_displayed_note: .res 1

.segment "CODE"

.proc reset
    sei
    cld
    ldx #$40
    stx $4017            ; Disable APU frame IRQ
    ldx #$FF
    txs
    inx
    stx PPUCTRL          ; Disable NMI
    stx PPUMASK          ; Disable rendering (Safe to write graphics)
    stx $4010            ; Disable DMC IRQ

    bit PPUSTATUS
@wait_vblank1:
    bit PPUSTATUS
    bpl @wait_vblank1
@wait_vblank2:
    bit PPUSTATUS
    bpl @wait_vblank2

    jsr init_screen
    lda #%00001000
    sta PPUMASK

    ldx #<music_data_untitled
    ldy #>music_data_untitled
    lda #1               ; 1 = NTSC mode
    jsr famistudio_init
    lda #0               ; Song index 0
    jsr famistudio_music_play
    lda #$FF
    sta last_displayed_note

@frame:
@wait_frame:
    bit PPUSTATUS
    bpl @wait_frame
    jsr famistudio_update
    lda famistudio_chn_note
    cmp last_displayed_note
    beq @frame
    sta last_displayed_note
    jsr draw_current_note
    jmp @frame
.endproc

; Initialize a blank nametable and a black background with white text.
.proc init_screen
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR

    ldy #$04
    lda #$20
@clear_nametable_page:
    ldx #$00
@clear_nametable:
    sta PPUDATA
    inx
    bne @clear_nametable
    dey
    bne @clear_nametable_page

    lda #$23
    sta PPUADDR
    lda #$C0
    sta PPUADDR
    lda #$00
    ldx #$40
@clear_attributes:
    sta PPUDATA
    dex
    bne @clear_attributes

    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #$0F
    ldx #$20
@set_black_palette:
    sta PPUDATA
    dex
    bne @set_black_palette

    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$01
    sta PPUADDR
    lda #$30
    sta PPUDATA

    lda #$00
    sta PPUSCROLL
    sta PPUSCROLL
    rts
.endproc

; Show the melody channel's active note in the font's ASCII tile set.
.proc draw_current_note
    bit PPUSTATUS
    lda #$21              ; Row 14, column 11: centered on the screen
    sta PPUADDR
    lda #$CB
    sta PPUADDR

    ldy #$00
@write_prefix:
    lda note_prefix,y
    beq @write_pitch
    sta PPUDATA
    iny
    bne @write_prefix

@write_pitch:
    lda famistudio_chn_note
    beq @write_rest
    sec
    sbc #$01              ; Note-table index 1 is C1; zero means silence
    ldx #$00
@find_octave:
    cmp #$0C
    bcc @write_note_name
    sec
    sbc #$0C
    inx
    bne @find_octave

@write_note_name:
    tay
    lda note_letters,y
    sta PPUDATA
    lda note_accidentals,y
    sta PPUDATA
    txa
    clc
    adc #$31              ; Convert octave 0.. to ASCII 1..
    sta PPUDATA
    lda #$20
    sta PPUDATA
    rts

@write_rest:
    ldy #$00
@write_rest_char:
    lda rest_text,y
    sta PPUDATA
    iny
    cpy #$04
    bne @write_rest_char
    rts
.endproc

.include "song.s"
.include "famistudio_ca65.s"

.segment "RODATA"
note_prefix:
    .byte "NOTE: ", $00
rest_text:
    .byte "REST"
note_letters:
    .byte "CCDDEFFGGAAB"
note_accidentals:
    .byte " # #  # # # "

.segment "VECTORS"
.word reset, reset, reset ; Assign interrupt entry points directly to boot logic

.segment "CHR"
.incbin "font.chr"       ; Fills out full 8192 byte window
