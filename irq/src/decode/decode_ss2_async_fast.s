.include "smc.inc"
.include "nes_mmio.inc"

.segment "DECODE"

; Decodes 16 bytes (64 samples) of 2-bit SSDPCM.
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
;       zp $0..$5
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
	jmp_dst2 = $2
	slope0   = $4
	slope1   = $5

.segment "DECODE"

	lda slopes_bank
	jsr mapper_set_bank_8000

	ldy #$00
	lda (ptr_slopes), y
	sta slope0
	iny                     ; y = 1
	lda (ptr_slopes), y
	sta slope1
	
	lda bits_bank
	jsr mapper_set_bank_8000
	
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1
	
	ldy #$00
	decode_byte:
		lda (ptr_bitstream), y              ; load byte in bitstream
		tax
		lda decode_byte_jump_tbl1_low, x    ; fetch jump table address to decode this nibble
		sta jmp_dst1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst1)                      ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_nibble1:
		inx
		inx
		sta last_sample
		stx idx_pcm_decode
		
		lda (ptr_bitstream), y              ; load byte in bitstream
		and #$0f                            ; extract upper nibble
		tax
		lda decode_byte_jump_tbl2_low, x    ; fetch jump table address to decode this nibble
		sta jmp_dst2
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp (jmp_dst2)                      ; jump to fetched address
		; --------------------------------- ;
	
	decode_byte_return_nibble2:
		inx
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
	adc #2
	sta ptr_slopes
	bcc @skip
	
	inc ptr_slopes + 1

@skip:
	rts

	.macro adc_slope_id    idx
		adc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro sbc_slope_id    idx
		sbc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro decode_internal    code, last_code
		; To save time, only change carry if last_code has a different sign than code
		; (or if it's omitted)
		.ifblank last_code
			.if code & $02
				sec
			.else
				clc
			.endif
		.elseif (code & $02) <> (last_code & $02)
			.if code & $02
				sec
			.else
				clc
			.endif
		.endif
		
		.if code & $02
			sbc_slope_id (code & $01)
		.else
			adc_slope_id (code & $01)
		.endif
	.endmacro

	.macro decode_code_offs0    code, last_code
		decode_internal code, last_code
		sta buf_pcm, x
	.endmacro
	
	.macro decode_code_offs1    code, last_code
		decode_internal code, last_code
		sta buf_pcm+1, x
	.endmacro

	.macro decode_nibble_ret1    nib
	.ident (.sprintf ("decode_nibble_ret1_%x", nib)):
		decode_code_offs0 (nib >> 2) & $03,
		decode_code_offs1 nib & $03,        (nib >> 2) & $03
		jmp decode_byte_return_nibble1
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs0 (nib >> 2) & $03,
		decode_code_offs1 nib & $03,        (nib >> 2) & $03
		jmp decode_byte_return_nibble2
	.endmacro

.segment "DECODE_TABLES"
	.align 256
	decode_unroll_1:
	.repeat 16, nib
		decode_nibble_ret1 nib
	.endrepeat

	decode_byte_jump_tbl2_low:
	.repeat 16, nib
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret2_%x", nib))))
	.endrepeat
	
	.align 256
	decode_unroll_2:
	.repeat 16, nib
		decode_nibble_ret2 nib
	.endrepeat

	.align 256
	decode_byte_jump_tbl1_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_nibble_ret1_%x", by >> 4))))
	.endrepeat
	
	
.endproc


