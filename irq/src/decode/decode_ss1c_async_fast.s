.include "smc.inc"

.segment "DECODE"

; Decodes 8 bytes (64 samples) of 1-bit SSDPCM.
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
.export decode_async
.proc decode_async

	.globalzp bits_bank, slopes_bank
	.globalzp idx_block, idx_pcm_decode, idx_superblock
	.globalzp superblock_length, last_sample, ptr_bitstream, ptr_slopes

	.import sblk_table, num_sblk_headers
	.import mapper_set_bank_8000
	.import load_next_superblock

	.global buf_pcm

	jmp_dst1 = $0
	slope0   = $2
	tmp_sample_1 = $4
	tmp_sample_2 = $5
	tmp_sample_3 = $6
	tmp_sample_4 = $7
	
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
		lsr a                               ; extract upper nibble
		lsr a
		lsr a
		lsr a
		tax
		lda decode_byte_jump_tbl1_low, x    ; fetch jump table address to decode this nibble
		sta jmp_dst1
		lda decode_byte_jump_tbl1_high, x
		sta jmp_dst1+1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst1)                      ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_nibble1:
		clc
		lda tmp_sample_1
		adc last_sample
		lsr a
		sta buf_pcm, x
		
		lda tmp_sample_2
		adc tmp_sample_1
		lsr a
		sta buf_pcm+1, x
		
		lda tmp_sample_3
		adc tmp_sample_2
		lsr a
		sta buf_pcm+2, x
		
		lda tmp_sample_4
		sta last_sample
		adc tmp_sample_3
		lsr a
		sta buf_pcm+3, x
		
		inx
		inx
		inx
		inx
		stx idx_pcm_decode
		
		lda (ptr_bitstream), y              ; load byte in bitstream
		and #$0f                            ; extract upper nibble
		tax
		lda decode_byte_jump_tbl2_low, x    ; fetch jump table address to decode this nibble
		sta jmp_dst1
		lda decode_byte_jump_tbl2_high, x   ; fetch jump table address to decode this nibble
		sta jmp_dst1+1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst1)                      ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_nibble2:
		clc
		lda tmp_sample_1
		adc last_sample
		lsr a
		sta buf_pcm, x
		
		lda tmp_sample_2
		adc tmp_sample_1
		lsr a
		sta buf_pcm+1, x
		
		lda tmp_sample_3
		adc tmp_sample_2
		lsr a
		sta buf_pcm+2, x
		
		lda tmp_sample_4
		sta last_sample
		adc tmp_sample_3
		lsr a
		sta buf_pcm+3, x
		
		inx
		inx
		inx
		inx
		stx idx_pcm_decode
		
		iny
		cpy #8
		beq @after
		jmp decode_byte

@after:
	; Bitstream pointer update
	clc
	lda ptr_bitstream
	adc #8
	sta ptr_bitstream
	bcc @nocarry
	
	inc ptr_bitstream + 1

@nocarry:
	txa
	and #$7f
	bne @skip                            ; don't move to the next block if sample position isn't at the
	;                                    ; start of the next block
	
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
			.if code & $01
				sec
			.else
				clc
			.endif
		.elseif (code & $01) <> (last_code & $01)
			.if code & $01
				sec
			.else
				clc
			.endif
		.endif
		
		.if code & $01
			sbc slope0
		.else
			adc slope0
		.endif
		
	.endmacro

	.macro decode_code_offs0    code, last_code
		decode_internal code, last_code
		sta tmp_sample_1
	.endmacro
	
	.macro decode_code_offs1    code, last_code
		decode_internal code, last_code
		sta tmp_sample_2
	.endmacro

	.macro decode_code_offs2    code, last_code
		decode_internal code, last_code
		sta tmp_sample_3
	.endmacro
	
	.macro decode_code_offs3    code, last_code
		decode_internal code, last_code
		sta tmp_sample_4
	.endmacro
	
	.macro decode_nibble_ret1    nib
	.ident (.sprintf ("decode_nibble_ret1_%x", nib)):
		decode_code_offs0 (nib >> 3) & $01,
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01
		decode_code_offs3 nib & $01,        (nib >> 1) & $01
		jmp decode_byte_return_nibble1
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs0 (nib >> 3) & $01,
		decode_code_offs1 (nib >> 2) & $01, (nib >> 3) & $01
		decode_code_offs2 (nib >> 1) & $01, (nib >> 2) & $01
		decode_code_offs3 nib & $01,        (nib >> 1) & $01
		jmp decode_byte_return_nibble2
	.endmacro

.segment "DECODE_TABLES"
	decode_unroll_1:
	.repeat 16, nib
		decode_nibble_ret1 nib
	.endrepeat
	
	decode_unroll_2:
	.repeat 16, nib
		decode_nibble_ret2 nib
	.endrepeat

	decode_byte_jump_tbl1_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret1_%x", nib))))
	.endrepeat

	decode_byte_jump_tbl1_high:
	.repeat 16, nib
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret1_%x", nib))))
	.endrepeat

	decode_byte_jump_tbl2_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat

	decode_byte_jump_tbl2_high:
	.repeat 16, nib
		.byte (.hibyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat
	
	
.endproc
