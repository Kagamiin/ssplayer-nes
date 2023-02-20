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
		bmi @neg_set                        ; check MSB to choose code path to decode it, since
		;                                   ; the unrolled code only decodes the bottom 7 bits
		
	@neg_clear:
		lda decode_byte_jump_tbl_low, x     ; fetch jump table address to decode this nibble
		sta jmp_dst1
		lda decode_byte_jump_tbl_high, x
		sta jmp_dst1+1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		clc
		adc slope0                          ; decode MSB
		sta buf_pcm, x
		jmp (jmp_dst1)                      ; jump to fetched address
		; --------------------------------- ;
		
	@neg_set:
		lda decode_byte_jump_tbl_low, x    ; fetch jump table address to decode this nibble
		sta jmp_dst1
		lda decode_byte_jump_tbl_high, x
		sta jmp_dst1+1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		sec
		sbc slope0                          ; decode MSB
		sta buf_pcm, x
		jmp (jmp_dst1)                      ; jump to fetched address
		; --------------------------------- ;
	
	decode_jump_table_return:
		sta last_sample
		txa
		clc
		adc #8
		tax
		stx idx_pcm_decode
		
		iny
		cpy #8
		bne decode_byte

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

	.macro decode_code    code, last_code, offset
		decode_internal code, last_code
		sta buf_pcm + offset, x
	.endmacro
	
	.macro decode_byte    by
	.ident (.sprintf ("decode_byte_%x", by)):
		decode_code (by >> 6) & $01,                , 1
		decode_code (by >> 5) & $01, (by >> 6) & $01, 2
		decode_code (by >> 4) & $01, (by >> 5) & $01, 3
		decode_code (by >> 3) & $01, (by >> 4) & $01, 4
		decode_code (by >> 2) & $01, (by >> 3) & $01, 5
		decode_code (by >> 1) & $01, (by >> 2) & $01, 6
		decode_code by & $01,        (by >> 1) & $01, 7
		jmp decode_jump_table_return
	.endmacro

.segment "DECODE_UNROLL"
	.repeat 128, by
		decode_byte by
	.endrepeat

.segment "DECODE_TABLES"
	decode_byte_jump_tbl_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_byte_%x", by & $7f))))
	.endrepeat

	decode_byte_jump_tbl_high:
	.repeat 256, by
		.byte (.hibyte (.ident (.sprintf ("decode_byte_%x", by & $7f))))
	.endrepeat
	
.endproc
