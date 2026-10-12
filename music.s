; WiiShop6502
; Written by meowcat767 - 2026

NOTE_COUNT = 16

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

; IDs

REST = 0;
G2 = 1
A2 = 2
B2 = 3
C3 = 4
D3 = 5
A4 = 6
B4 = 7
C5 = 8
CS5 = 9
D5 = 10
EB5 = 11
E5 = 12
FS5 = 13
G5 = 14
A5 = 15
BB5 = 16
B5 = 17
C6 = 18
D6 = 19

PITCH_COUNT = 20

; index 0 is REST
; the timer tables contain the low and high bytes of the 11-bit pulse timer values for each pitch

pitch_lo:
   .byte $00
   .byte $74
   .byte $F8
   .byte $89
   .byte $56
   .byte $F9
   .byte $FD
   .byte $E1
   .byte $D5
   .byte $C9
   .byte $BD
   .byte $B3
   .byte $A9
   .byte $96
   .byte $8E
   .byte $7E
   .byte $77
   .byte $70
   .byte $6A
   .byte $5E

pitch_hi:
    .byte $00         
    .byte $04         
    .byte $03         
    .byte $03         
    .byte $03         
    .byte $02         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00         
    .byte $00        
    .byte $00         
    .byte $00         

; intro riff
intro_melody_pitch:
    .byte E5, G5, D5
    .byte E5, G5, D5
    .byte E5, G5, D5
    .byte E5, G5, D5

intro_melody_duration:
    .byte 8, 8, 8
    .byte 8, 8, 8
    .byte 8, 8, 8
    .byte 8, 8, 8

intro_bass_pitch
    .byte D3, D3, D3, D3
    .byte D3, D3, D3, D3
    .byte D3, D3, D3, D3

intro_bass_duration:
    .byte 8, 8, 8, 8
    .byte 8, 8, 8, 8
    .byte 8, 8, 8, 8

INTRO_MELODY_COUNT = 12
INTRO_BASS_COUNT = 12

; SECTION A
section_a_melody_pitch:
    .byte D5, F55, A5, FS5, D5
    .byte C5, E5, G5, E5, C5
    .byte B4, D5, G5, D5, B4
    .byte A4, CS5, E5, G5, FS5

section_a_melody_duration:
    .byte 12, 12, 12, 12, 18
    .byte 12, 12, 12, 12, 18
    .byte 12, 12, 12, 12, 18
    .byte 12, 12, 12, 12, 18

section_a_bass_pitch:
    .byte G2, D3, G2, A2

section_a_bass_duration:
    .byte 60, 60, 60, 60

SECTION_A_MELODY_COUNT = 20
SECTION_A_BASS_COUNT = 4

; SECTION B
section_b_melody_pitch:
    .byte E5, G5, C6, E5, G5, C6
    .byte E5, G5, B5, E5, G5, B5
    .byte E5, G5, A5, E5, G5, A5
    .byte D5, FS5, A5

section_b_melody_duration:
    .byte 6, 6, 6, 6, 12
    .byte 6, 6, 6, 6, 12
    .byte 6, 6, 6, 6, 12
    .byte 18, 18, 36

section_b_bass_pitch:
    .byte C3, B2, A2, D3

section_b_bass_duration:
    .byte 60, 60, 60, 60

SECTION_B_MELODY_COUNT = 21
SECTION_B_BASS_COUNT = 4

; SECTION C

section_c_melody_pitch:
    .byte EB5, G5, D6, EB5, G5, D6
    .byte EB5, G5, C6, EB5, G5, C6
    .byte C5, EB5, BB5, C5, EB5, BB5
    .byte C5, EB5, A5, C5, EB5, A5

section_c_melody_duration:
    .byte 8, 8, 18, 8, 8, 18
    .byte 8, 8, 18, 8, 8, 18
    .byte 8, 8, 18, 8, 8, 18
    .byte 8, 8, 18, 8, 8, 24

section_c_bass_pitch:
    .byte G2, G2, D3, D3
    .byte C3, C3, B2, B2
    .byte A2, A2, D3, D3

setion_c_bass_duration:
    .byte 36, 36, 36, 36
    .byte 36, 36, 36, 36
    .byte 36, 36, 36, 36

SECTION_C_MELODY_COUNT = 24
SECTION_C_BASS_COUNT = 12

.segment "VECTORS"
.word reset, reset, reset

.segment "CHARS"
.res 8192, $00
