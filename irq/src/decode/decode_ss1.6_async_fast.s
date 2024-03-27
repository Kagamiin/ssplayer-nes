.include "smc.inc"
.include "nes_mmio.inc"

.segment "DECODE"

; Decodes 16 bytes (80 samples) of 1.6-bit SSDPCM.
; If the end of the superblock is reached, triggers the next superblock to be loaded.
; uses:
;	bits_bank
;	slopes_bank
;	idx_block
;	idx_pcm_decode
;	idx_superblock
;	superblock_length
;	last_sample
;	ptr_bitstream
;	ptr_slopes
; updates:
;	idx_block
;	idx_pcm_decode
;	last_sample
;	ptr_bitstream
;	ptr_slopes
; clobbers:
;	a, x, y
;       zp $0..$2
.exportzp SAMPLES_PER_DECODE_CALL
SAMPLES_PER_DECODE_CALL = 80

.global buf_pcm

.export decode_async
.proc decode_async

	.globalzp bits_bank, slopes_bank
	.globalzp idx_block, idx_pcm_decode, idx_superblock
	.globalzp superblock_length, last_sample, ptr_bitstream, ptr_slopes

	.import sblk_table, num_sblk_headers
	.import mapper_set_bank_8000
	.import load_next_superblock


	jmp_dst  = $0
	slope0   = $2

.segment "DECODE"

	lda slopes_bank
	jsr mapper_set_bank_8000

	ldy #$00
	lda (ptr_slopes), y
	sta slope0
	
	lda bits_bank
	jsr mapper_set_bank_8000
	decode_byte:
		lda (ptr_bitstream), y              ; load byte in bitstream
		tax
		lda decode_byte_jump_tbl1_low, x    ; fetch jump table address to decode this part
		sta jmp_dst
		lda decode_byte_jump_tbl1_high, x
		sta jmp_dst + 1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst)                       ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_part1:
		inx
		sta last_sample
		stx idx_pcm_decode
		
		lda (ptr_bitstream), y              ; load byte in bitstream
		tax
		lda decode_byte_jump_tbl2_low, x    ; fetch jump table address to decode this part
		sta jmp_dst
		lda decode_byte_jump_tbl2_high, x
		sta jmp_dst + 1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst)                       ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_part2:
		inx
		sta last_sample
		stx idx_pcm_decode
		
		iny
		cpy #16
		bne decode_byte

@after:
	; Bitstream pointer update
	clc
	lda ptr_bitstream
	adc #16
	sta ptr_bitstream
	bcc @nocarry
	
	inc ptr_bitstream + 1

@nocarry:
	inc idx_block
	lda superblock_length
	cmp idx_block                        ; check if we need to load the next superblock
	bne @slope_update

	inc idx_superblock
	jmp load_next_superblock             ; load next superblock

@slope_update:
	clc
	lda ptr_slopes                       ; update slope pointer
	adc #1
	sta ptr_slopes
	bcc @skip
	
	inc ptr_slopes + 1

@skip:
	rts

	.macro decode_internal    code, last_code
		; To save time, only change carry if last_code has a different sign than code
		; (or if it's omitted)
		.ifblank last_code
			.if (code .MOD 3) = 2
			.elseif (code .MOD 3) = 1
				sec
			.else
				clc
			.endif
		.elseif (code .MOD 3) <> (last_code .MOD 3)
			.if (code .MOD 3) = 2
			.elseif (code .MOD 3) = 1
				sec
			.else
				clc
			.endif
		.endif
		
		.if (code .MOD 3) = 2
		.elseif (code .MOD 3) = 1
			sbc slope0
		.else
			adc slope0
		.endif
	.endmacro

	.macro decode_codeword_part1   cw
	.ident (.sprintf ("decode_codeword_part1_%x", cw)):
	.scope
		w1 := cw .MOD 3
		cw1 := cw / 3
		w0 := cw1 .MOD 3
		decode_internal  w0
		sta buf_pcm, x
		inx
		decode_internal  w1, w0
		sta buf_pcm, x
		jmp decode_byte_return_part1
	.endscope
	.endmacro
	
	.macro decode_codeword_part2   cw
	.ident (.sprintf ("decode_codeword_part2_%x", cw)):
	.scope
		w4 := cw .MOD 3
		cw4 := cw / 3
		w3 := cw4 .MOD 3
		cw3 := cw4 / 3
		w2 := cw3 .MOD 3
		decode_internal  w2
		sta buf_pcm, x
		inx
		decode_internal  w3, w2
		sta buf_pcm, x
		inx
		decode_internal  w4, w3
		sta buf_pcm, x
		jmp decode_byte_return_part2
	.endscope
	.endmacro

.segment "DECODE"
	.repeat 9, bcw
		decode_codeword_part1 bcw
	.endrepeat

	.repeat 27, bcw
		decode_codeword_part2 bcw
	.endrepeat

.segment "DECODE_TABLES"
	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 9, bcw
		.repeat 27
			.byte (.lobyte (.ident (.sprintf ("decode_codeword_part1_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.lobyte (.ident ("decode_codeword_part1_8")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_high:
	.repeat 9, bcw
		.repeat 27
			.byte (.hibyte (.ident (.sprintf ("decode_codeword_part1_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.hibyte (.ident ("decode_codeword_part1_8")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl2_low:
	.repeat 9
		.repeat 27, bcw
			.byte (.lobyte (.ident (.sprintf ("decode_codeword_part2_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.lobyte (.ident ("decode_codeword_part2_1a")))
	.endrepeat

	.align 256
	decode_byte_jump_tbl2_high:
	.repeat 9
		.repeat 27, bcw
			.byte (.hibyte (.ident (.sprintf ("decode_codeword_part2_%x", bcw))))
		.endrepeat
	.endrepeat
	.repeat 13 ; failsafe
		.byte (.hibyte (.ident ("decode_codeword_part2_1a")))
	.endrepeat

.endproc




