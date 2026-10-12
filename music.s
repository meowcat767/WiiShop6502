
; Wii Shop Channel theme for the NES (6502)
; written by meowcat767 - 2026


SECTION_COUNT = 4

.segment "HEADER"
.byte $4E, $45, $53, $1A
.byte $02               ; 32 KB PRG ROM
.byte $00               ; CHR RAM
.byte $00, $00          ; Mapper 0
.byte $00, $00, $00, $00, $00, $00, $00, $00 ; reserved header bytes

.segment "ZEROPAGE"
note_index:         .res 1
note_ticks:         .res 1
section_index:      .res 1

pitch1_ptr:         .res 2
pitch2_ptr:         .res 2
duration_ptr:       .res 2

bass_index:         .res 1
bass_ticks:         .res 1
bass_section_index: .res 1
bass_pitch_ptr:     .res 2
bass_duration_ptr:  .res 2

current_bass_pitch: .res 1
bass_timer_lo:      .res 1
bass_timer_hi:      .res 1

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
    stx $4010           ; disable DMC IRQ
    stx $4015           ; disable APU channels
    bit $2002

@wait1:
    bit $2002
    bpl @wait1
@wait2:
    bit $2002
    bpl @wait2

    ; Initialize playback variables to start at Intro (Section 0)
    lda #$00
    sta note_index
    sta bass_index
    sta section_index
    sta bass_section_index

    jsr load_note
    jsr load_bass

frame_loop:
@wait_frame:
    bit $2002
    bpl @wait_frame

    ; --- Handle Melody / Chords ---
    dec note_ticks
    bne @bass_tick

    inc note_index
    ldx section_index
    lda section_note_counts,x
    cmp note_index
    bne @note_index_ok

    ; Advance section logic
    lda #$00
    sta note_index
    inc section_index
    lda section_index
    cmp #SECTION_COUNT
    bcc @note_index_ok
    lda #$01            ; Loop back to Section A (skip Intro on loop)
    sta section_index
@note_index_ok:
    jsr load_note

    ; --- Handle Bass ---
@bass_tick:
    dec bass_ticks
    bne @next_frame

    inc bass_index
    ldx bass_section_index
    lda section_bass_counts,x
    cmp bass_index
    bne @bass_index_ok

    lda #$00
    sta bass_index
    inc bass_section_index
    lda bass_section_index
    cmp #SECTION_COUNT
    bcc @bass_index_ok
    lda #$01            ; Loop back to Section A bass
    sta bass_section_index
@bass_index_ok:
    jsr load_bass

@next_frame:
    jmp frame_loop
.endproc

; --- Load and play the current note / chord block ---
.proc load_note
    ldx section_index
    txa
    asl a
    tax

    lda section_pitch1_ptrs,x
    sta pitch1_ptr
    lda section_pitch1_ptrs+1,x
    sta pitch1_ptr+1

    lda section_pitch2_ptrs,x
    sta pitch2_ptr
    lda section_pitch2_ptrs+1,x
    sta pitch2_ptr+1

    lda section_duration_ptrs,x
    sta duration_ptr
    lda section_duration_ptrs+1,x
    sta duration_ptr+1

    ldy note_index
    lda (duration_ptr),y
    sta note_ticks

    ; Check if Pulse 1 is resting
    lda (pitch1_ptr),y
    beq @pulse1_rest
    tax
    lda #$1F            ; Enable Pulse 1, Pulse 2, and Triangle
    sta $4015
    lda #$08            ; Disable pulse sweep
    sta $4001
    lda #$BF            ; 50% duty, constant volume max
    sta $4000
    lda pitch_lo,x
    sta $4002
    lda pitch_hi,x
    ora #$F8            ; Reload pulse length counter
    sta $4003
    jmp @do_pulse2

@pulse1_rest:
    lda #$00
    sta $4000
    sta $4003

@do_pulse2:
    ldy note_index
    lda (pitch2_ptr),y
    beq @pulse2_rest
    tax
    lda #$08
    sta $4005
    lda #$BF            ; 50% duty, constant volume max
    sta $4004
    lda pitch_lo,x
    sta $4006
    lda pitch_hi,x
    ora #$F8
    sta $4007
    rts

@pulse2_rest:
    lda #$00
    sta $4004
    sta $4007
    rts
.endproc

; --- Load and play the current bass note ---
.proc load_bass
    ldx bass_section_index
    txa
    asl a
    tax
    lda section_bass_pitch_ptrs,x
    sta bass_pitch_ptr
    lda section_bass_pitch_ptrs+1,x
    sta bass_pitch_ptr+1
    lda section_bass_duration_ptrs,x
    sta bass_duration_ptr
    lda section_bass_duration_ptrs+1,x
    sta bass_duration_ptr+1

    ldy bass_index
    lda (bass_duration_ptr),y
    sta bass_ticks
    lda (bass_pitch_ptr),y
    sta current_bass_pitch
    beq @bass_rest

    ; Setup Triangle Channel
    lda #$FF
    sta $4008           ; Linear counter control
    ldx current_bass_pitch
    lda pitch_lo,x
    sec
    sbc #$01
    sta bass_timer_lo
    lda pitch_hi,x
    sbc #$00
    sta bass_timer_hi
    lsr bass_timer_hi
    ror bass_timer_lo
    lda bass_timer_lo
    sta $400A
    lda bass_timer_hi
    and #$07
    ora #$F8
    sta $400B
    rts

@bass_rest:
    lda #$00
    sta $4008
    sta $400B
    rts
.endproc

; =============================================================================
; LOOKUP TABLES & DATA STRUCTURES
; =============================================================================

section_pitch1_ptrs:
    .word intro_melody_p1
    .word section_a_melody_p1
    .word section_b_melody_p1
    .word section_c_melody_p1

section_pitch2_ptrs:
    .word intro_melody_p2
    .word section_a_melody_p2
    .word section_b_melody_p2
    .word section_c_melody_p2

section_duration_ptrs:
    .word intro_duration
    .word section_a_duration
    .word section_b_duration
    .word section_c_duration

section_note_counts:
    .byte INTRO_COUNT
    .byte SECTION_A_COUNT
    .byte SECTION_B_COUNT
    .byte SECTION_C_COUNT

section_bass_pitch_ptrs:
    .word intro_bass_pitch
    .word section_a_bass_pitch
    .word section_b_bass_pitch
    .word section_c_bass_pitch

section_bass_duration_ptrs:
    .word intro_bass_duration
    .word section_a_bass_duration
    .word section_b_bass_duration
    .word section_c_bass_duration

section_bass_counts:
    .byte INTRO_BASS_COUNT
    .byte SECTION_A_BASS_COUNT
    .byte SECTION_B_BASS_COUNT
    .byte SECTION_C_BASS_COUNT

; --- Note Definitions ---
REST = 0
G2  = 1
A2  = 2
B2  = 3
C3  = 4
D3  = 5
A4  = 6
B4  = 7
C5  = 8
CS5 = 9
D5  = 10
EB5 = 11
E5  = 12
FS5 = 13
G5  = 14
A5  = 15
BB5 = 16
B5  = 17
C6  = 18
D6  = 19
EB4 = 20
G4  = 21

; --- Correct NTSC APU Period Target Low/High Tables ---
pitch_lo:
   .byte $00, $74, $F8, $89, $56, $F9, $FD, $E1, $D5, $C9, $BD, $B3, $A9, $96, $8E, $7E, $77, $70, $6A, $5E, $67, $1C
pitch_hi:
    .byte $00, $04, $03, $03, $03, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01

; --- INTRO DATA ---
INTRO_COUNT = 12
intro_melody_p1: .byte E5, G5, D5, E5, G5, D5, E5, G5, D5, E5, G5, D5
intro_melody_p2: .byte REST, REST, REST, REST, REST, REST, REST, REST, REST, REST, REST, REST
intro_duration:  .byte 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8

INTRO_BASS_COUNT = 4
intro_bass_pitch:    .byte D3, D3, D3, D3
intro_bass_duration: .byte 24, 24, 24, 24

; --- SECTION A DATA ---
SECTION_A_COUNT = 20
section_a_melody_p1: .byte D5, FS5, A5, FS5, D5,  C5, E5, G5, E5, C5,  B4, D5, G5, D5, B4,  A4, CS5, E5, G5, FS5
section_a_melody_p2: .byte FS5, A5, C6, A5, FS5,  E5, G5, B5, G5, E5,  D5, FS5, A5, FS5, D5, CS5, E5, G5, B5, A5
section_a_duration:  .byte 12, 12, 12, 12, 18,   12, 12, 12, 12, 18,  12, 12, 12, 12, 18,  12, 12, 12, 12, 18

SECTION_A_BASS_COUNT = 4
section_a_bass_pitch:    .byte G2, D3, G2, A2
section_a_bass_duration: .byte 66, 66, 66, 66

; --- SECTION B DATA ---
SECTION_B_COUNT = 21
section_b_melody_p1: .byte E5, G5, C6, E5, G5, C6,  E5, G5, B5, E5, G5, B5,  E5, G5, A5, E5, G5, A5,  D5, FS5, A5
section_b_melody_p2: .byte C5, E5, G5, C5, E5, G5,  B4, E5, G5, B4, E5, G5,  A4, E5, G5, A4, E5, G5,  B4, D5,  FS5
section_b_duration:  .byte 6,  6,  6,  6,  6,  6,   6,  6,  6,  6,  6,  6,   6,  6,  6,  6,  6,  6,   18, 18,  36

SECTION_B_BASS_COUNT = 4
section_b_bass_pitch:    .byte C3, B2, A2, D3
section_b_bass_duration: .byte 45, 45, 45, 45

; --- SECTION C DATA ---
SECTION_C_COUNT = 24
section_c_melody_p1: .byte EB5, G5, D6, EB5, G5, D6,  EB5, G5, C6, EB5, G5, C6,  C5, EB5, BB5, C5, EB5, BB5,  C5, EB5, A5, C5, EB5, A5
section_c_melody_p2: .byte G4,  C5, EB5, G4, C5, EB5, G4,  C5, EB5, G4, C5, EB5, EB4, A4, C5,  EB4, A4, C5,   EB4, A4,  C5, EB4, A4,  C5
section_c_duration:  .byte 8,   8,  18, 8,  8,  18,  8,   8,  18, 8,  8,  18,  8,   8,  18,  8,   8,  18,   8,   8,   18, 8,   8,   24

SECTION_C_BASS_COUNT = 12
section_c_bass_pitch:    .byte G2, G2, D3, D3, C3, C3, B2, B2, A2, A2, D3, D3
section_c_bass_duration: .byte 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20

.segment "VECTORS"
.word reset, reset, reset

.segment "CHARS"
.res 8192, $00