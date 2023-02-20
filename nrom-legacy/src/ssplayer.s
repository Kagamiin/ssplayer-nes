
.include "playback.inc"

.import build_decode_tables
.import decode_block
.import load_next_superblock

.segment "HEADER"

INES_MAPPER = 0 ; 0 = NROM
INES_MIRROR = 1 ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0 ; 1 = battery backed SRAM at $6000-7FFF

	.byte 'N', 'E', 'S', $1A ; ID
	.byte $02 ; 16k PRG chunk count
	.byte $00 ; 8k CHR chunk count
	.byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
	.byte (INES_MAPPER & %11110000)
	.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

.globalzp tmp_addr, idx_pcm_playback, block_slope, tmp_shortbuf
.global buf_pcm

.segment "CODE"
;.align 256
main_loop_entry:
	lda #(256 - 66)
	sta idx_pcm_playback
	jsr decode_block
	jsr decode_block
	lda #0
	sta idx_pcm_playback
	ldy #18
playback_loop_1:                       ;  1   0
	@delay:                        ; 89  89
		dey
		bne @delay
	ldy #18                        ;  2  91
	play_sample_inline_clobber_ax  ; 16  -7 - sample playback at 91 + 11 = 102
	nop                            ;  2  -5
	nop                            ;  2  -3
	bpl playback_loop_1            ;  2  -1

	ldy #8                         ;  2   1
	@delay2:                       ; 39  40
		dey
		bne @delay2
.assert >(* - 1) = >playback_loop_1, error, "playback_loop_1 is not page-aligned"

	nop                            ;  2  42
	jsr decode_block               ;  6  48
	;                              ;  ?   6   return cycle alignment of decode_block is 6
	nop                            ;  2   8
	nop                            ;  2  10
	ldy #15                        ;  2  12   14 * 5 + 4 = 74 loop delay cycles
	jmp playback_loop_2            ;  3  15   15 + 74 = 89

playback_loop_2:                       ;  1   0
	@delay:                        ; 89  89
		dey
		bne @delay
	ldy #18                        ;  2  91
	play_sample_inline_clobber_ax  ; 16  -7 - sample playback at 91 + 11 = 102
	nop                            ;  2  -5
	nop                            ;  2  -3
	bmi playback_loop_2            ;  2  -1

	ldy #8                         ;  2   1
	@delay2:                       ; 39  40
		dey
		bne @delay2
.assert >(* - 1) = >playback_loop_2, error, "playback_loop_2 is not page-aligned"

	nop                            ;  2  42
	jsr decode_block               ;  6  48
	;                              ;  ?   6   return cycle alignment of decode_block is 6
	nop                            ;  2   8
	nop                            ;  2  10
	ldy #15                        ;  2  12   14 * 5 + 4 = 74 loop delay cycles
	jmp playback_loop_1            ;  3  15   15 + 74 = 89

.segment "CODE"
reset:
	; clear memory
	ldx #7
	lda #0
	sta tmp_addr
	tay
	@loop:
		stx tmp_addr + 1
		@inner:
			dey
			sta (tmp_addr), y
			bne @inner
		dex
		bpl @loop
	jsr build_decode_tables
	jsr load_next_superblock
	jmp main_loop_entry

.segment "VECTORS"

	.addr 0             ; nmi
	.addr reset         ; reset
	.addr 0             ; irq

