
.include "nes_mmio.inc"

.segment "CHR"

.incbin "cuba-baion-bg.chr"
.incbin "cuba-baion-spr.chr"

.segment "INIT"

nametable_data:
	.incbin "cuba-baion.str"

.proc load_nametable_stripes
.global buf_oam, ppuctrl_shadow

	data_ptr = $0
	tmp_length = $2

	lda #<nametable_data
	sta data_ptr
	lda #>nametable_data
	sta data_ptr + 1
	ldy #0
	
start:
	lda (data_ptr), y
	bmi finish
	iny
	bne @nocarry
	inc data_ptr + 1
@nocarry:
	sta PPUADDR
	jsr load_byte
	sta PPUADDR
	
	jsr load_byte
	sta tmp_length
	bit tmp_length
	jsr set_direction
	lda tmp_length
	and #$3f
	tax
	bvs run
literal:
	@loop:
		jsr load_byte
		sta PPUDATA
		dex
		bpl @loop
	bvc start             ; always jumps
run:
	jsr load_byte
	@loop:
		sta PPUDATA
		dex
		bpl @loop
	bvs start             ; always jumps
finish:
	rts

	; subroutines
	set_direction:
		bmi @vertical
		lda ppuctrl_shadow
		and #%11111011     ; set autoincrement mode to horizontal
		sta PPUCTRL
		rts
	@vertical:
		lda ppuctrl_shadow
		ora #%00000100     ; set autoincrement mode to vertical
		sta PPUCTRL
		rts
	
	load_byte:
		lda (data_ptr), y
		iny
		bne @nocarry
		inc data_ptr + 1
	@nocarry:
		rts
	
.endproc

; Assumes rendering is turned off.
.export load_graphics
.proc load_graphics
.global buf_oam, ppuctrl_shadow

	lda PPUSTATUS      ; reset PPU access ports

	jsr load_nametable_stripes
	
	lda #$3f
	sta PPUADDR
	lda #$00          ; set PPUADDR to start of palettes
	sta PPUADDR
	ldy #0
	@loop_palette:
		lda palette_data, y
		sta PPUDATA
		iny
		cpy #palette_data_size
		bne @loop_palette
	
	ldy #0
	@loop_oam_buffer:
		lda oam_data, y
		sta buf_oam, y
		iny
		cpy #oam_data_size
		bne @loop_oam_buffer
	
	lda #$ff
	@loop_pad_oam_buffer:
		sta buf_oam, y
		iny
		bne @loop_pad_oam_buffer
	
	rts
	
palette_data:
	.byte $0f, $2d, $10, $30 ; gray background
	.byte $0f, $2d, $10, $30
	.byte $0f, $2d, $10, $30
	.byte $0f, $2d, $10, $30
	
	.byte $0f, $2d, $10, $30
	.byte $0f, $07, $17, $28 ; brown and yellow
	.byte $0f, $1c, $21, $3c ; cyan highlights
	.byte $0f, $19, $29, $3a ; green
	palette_data_size = * - palette_data

oam_data:
	.byte $6e, $2f, $02, $9b
	.byte $6e, $2d, $02, $93
	.byte $54, $0f, $02, $7d
	.byte $54, $0d, $02, $75
	.byte $7e, $6d, $03, $80
	.byte $7e, $6b, $03, $78
	.byte $7e, $69, $03, $70
	.byte $7e, $67, $03, $68
	.byte $7e, $65, $03, $60
	.byte $6e, $5d, $03, $80
	.byte $6e, $5b, $03, $78
	.byte $6e, $59, $03, $70
	.byte $6e, $57, $03, $68
	.byte $6e, $55, $03, $60
	.byte $6e, $53, $03, $58
	.byte $5e, $4b, $03, $78
	.byte $5e, $49, $03, $70
	.byte $5e, $47, $03, $68
	.byte $5e, $45, $03, $60
	.byte $5e, $43, $03, $58
	.byte $5e, $41, $03, $50
	.byte $4e, $39, $03, $70
	.byte $4e, $37, $03, $68
	.byte $4e, $35, $03, $60
	.byte $4e, $33, $03, $58
	.byte $4e, $31, $03, $50
	.byte $46, $2b, $03, $78
	.byte $46, $29, $03, $70
	.byte $46, $27, $03, $68
	.byte $47, $25, $01, $53
	.byte $47, $23, $01, $4b
	.byte $47, $21, $01, $43
	.byte $37, $1b, $01, $6b
	.byte $37, $19, $01, $63
	.byte $37, $17, $01, $5b
	.byte $37, $15, $01, $53
	.byte $37, $13, $01, $4b
	.byte $37, $11, $01, $43
	.byte $27, $0b, $01, $6b
	.byte $27, $09, $01, $63
	.byte $27, $07, $01, $5b
	.byte $27, $05, $01, $53
	.byte $27, $03, $01, $4b
	.byte $27, $01, $01, $43
	oam_data_size = * - oam_data

.endproc
