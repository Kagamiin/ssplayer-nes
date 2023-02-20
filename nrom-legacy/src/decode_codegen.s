
.globalzp tmp_addr, tmp_ret_addr
.globalzp tmp_jmptbl_start_offset, tmp_ret_template_offset, tmp_src_addr, tmp_mask
.globalzp block_slope

.global buf_pcm
.global decode_byte_jump_tbl1_low, decode_byte_jump_tbl1_high
.global decode_byte_jump_tbl2_low, decode_byte_jump_tbl2_high

.import decode_code_array
.import decode_byte_after1
.import decode_byte_after2

.segment "CODE"

;.align 16
decode_templates_start:
.scope decode_template_bit_0
start:
	clc
	adc block_slope
	sta buf_pcm, x
	inx
end:
size := end - start
.endscope

.scope decode_template_bit_1
start:
	sec
	sbc block_slope
	sta buf_pcm, x
	inx
end:
size := end - start
.endscope

decode_template_jump1:
	jmp decode_byte_after1
decode_template_jump2:
	jmp decode_byte_after2

.assert decode_template_bit_0::size = decode_template_bit_1::size, error, "decode templates have different sizes"
.assert >decode_templates_start = >(* - 1), error, "decode templates are not page-aligned"

decode_template_size := decode_template_bit_0::size

.export build_decode_tables
build_decode_tables:
	lda #<decode_code_array
	sta tmp_addr
	lda #>decode_code_array
	sta tmp_addr + 1
	lda #>decode_template_bit_0::start        ; HACK: forcing code templates to be in the same page
	sta tmp_src_addr + 1
	
	lda #$00
	sta tmp_jmptbl_start_offset
	lda #<decode_template_jump1
	sta tmp_ret_template_offset
	
	jsr build_table
	
	lda #$20
	sta tmp_jmptbl_start_offset
	lda #<decode_template_jump2
	sta tmp_ret_template_offset
	
	jsr build_table
	
	rts

build_table:
	ldx #$0f
	@loop:
		txa
		clc
		adc tmp_jmptbl_start_offset
		tay
		lda tmp_addr
		sta decode_byte_jump_tbl1_low, y
		lda tmp_addr + 1
		sta decode_byte_jump_tbl1_low + $10, y
		lda #$08
		sta tmp_mask
		@inner:
			txa
			and tmp_mask
			bne @bit1
		@bit0:
			lda #<decode_template_bit_0::start
			sta tmp_src_addr
			jmp @copy
		@bit1:
			lda #<decode_template_bit_1::start
			sta tmp_src_addr

		@copy:
			lda #decode_template_size            ; HACK: forcing code templates to have the same sizes
			jsr write_bytes

			lsr tmp_mask
			bne @inner

		lda tmp_ret_template_offset
		sta tmp_src_addr
		lda #3
		jsr write_bytes
		dex
		bpl @loop
	rts

write_bytes:
	tay
	pha
	@loop:
		lda (tmp_src_addr), y
		sta (tmp_addr), y
		dey
		bpl @loop
	pla
	clc
	adc tmp_addr
	sta tmp_addr
	bcc @no_carry
	inc tmp_addr + 1
@no_carry:
	rts

