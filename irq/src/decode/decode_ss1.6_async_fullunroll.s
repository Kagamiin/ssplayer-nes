.include "smc.inc"
.include "nes_mmio.inc"

.segment "DECODE_FIXBANK"

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

	z0       = $0
	slope0   = $2

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
		lda decode_byte_jump_tbl_low, x     ; fetch jump table address to decode this byte
		sta $0
		lda decode_byte_jump_tbl_high, x
		sta $1
		
		lda last_sample                     ; load temporary regs
		ldx idx_pcm_decode
		jmp ($0000)                         ; jump to fetched address
	decode_jump_table_return:
		sta last_sample
		inx
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

.segment "DECODE_UNROLL"
	
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
	
.macro decode_byte   cw
	.ident (.sprintf ("decode_byte_%02x", cw)):
	.scope
		w4 := cw .MOD 3
		cw4 := cw / 3
		w3 := cw4 .MOD 3
		cw3 := cw4 / 3
		w2 := cw3 .MOD 3
		cw2 := cw3 / 3
		w1 := cw2 .MOD 3
		cw1 := cw2 / 3
		w0 := cw1 .MOD 3
		decode_internal  w0
		sta buf_pcm, x
		inx
		decode_internal  w1, w0
		sta buf_pcm, x
		inx
		decode_internal  w2, w1
		sta buf_pcm, x
		inx
		decode_internal  w3, w2
		sta buf_pcm, x
		inx
		decode_internal  w4, w3
		sta buf_pcm, x
		jmp decode_jump_table_return
	.endscope
.endmacro

	; This macro generates 243 segments of code to decode each possible codeword from the bitstream.
	.repeat 243, by
		decode_byte by
	.endrepeat

.segment "DECODE_TABLES"
	; This segment contains stripped jump tables to the 243 different segments of code
	decode_byte_jump_tbl_low:
	.repeat 243, by
		.byte (.lobyte (.ident (.sprintf ("decode_byte_%02x", by))))
	.endrepeat
	.repeat 13
		.byte (.lobyte (.ident ("decode_byte_f2")))
	.endrepeat
	
	decode_byte_jump_tbl_high:
	.repeat 243, by
		.byte (.hibyte (.ident (.sprintf ("decode_byte_%02x", by))))
	.endrepeat
	.repeat 13
		.byte (.lobyte (.ident ("decode_byte_f2")))
	.endrepeat
	
.endproc
