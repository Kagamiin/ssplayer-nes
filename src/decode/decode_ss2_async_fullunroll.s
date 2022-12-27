.include "smc.inc"
.include "nes_mmio.inc"

.globalzp idx_superblock, idx_block, idx_pcm_decode
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample
.globalzp bits_bank, slopes_bank

.import sblk_table, num_sblk_headers
.import mapper_set_bank_8000

.global buf_pcm

.segment "DECODE"

;.proc jump_z0_indirect
;	jmp ($0000)
;.endproc

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
; updates:
;	idx_block
;	idx_pcm_decode
;	last_sample
;	ptr_bitstream
; clobbers:
;	a, x, y
;       zp $0..$4
.export decode_ss2_async
.proc decode_ss2_async

	slope0   = $2
	slope1   = $3

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
	
	ldy #$00
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

	.macro decode_code_0
		clc
		adc slope0
		sta buf_pcm, x
		inx
	.endmacro

	.macro decode_code_1
		clc
		adc slope1
		sta buf_pcm, x
		inx
	.endmacro

	.macro decode_code_2
		sec
		sbc slope0
		sta buf_pcm, x
		inx
	.endmacro

	.macro decode_code_3
		sec
		sbc slope1
		sta buf_pcm, x
		inx
	.endmacro

	.macro decode_byte by
	.ident (.sprintf ("decode_byte_%02x", by)):
		.ident (.sprintf ("decode_code_%x", (by >> 6) & $03))
		.ident (.sprintf ("decode_code_%x", (by >> 4) & $03))
		.ident (.sprintf ("decode_code_%x", (by >> 2) & $03))
		.ident (.sprintf ("decode_code_%x", by & $03))
		jmp decode_jump_table_return
	.endmacro

.segment "DECODE_UNROLL"
	.repeat 256, by
		decode_byte by
	.endrepeat

.segment "DECODE_TABLES"
	decode_byte_jump_tbl_low:
	.repeat 256, by
		.byte (.lobyte (.ident (.sprintf ("decode_byte_%02x", by))))
	.endrepeat
	
	decode_byte_jump_tbl_high:
	.repeat 256, by
		.byte (.hibyte (.ident (.sprintf ("decode_byte_%02x", by))))
	.endrepeat
	
.endproc


; Loads the next superblock in the stream.
; If end of superblock list is reached, loops back to the beginning.
; uses:
;	idx_superblock
; updates:
;	idx_block
;	idx_superblock
;       bits_bank
;       slopes_bank
;	ptr_bitstream
;	ptr_slopes
;	last_sample
;	superblock_length
; clobbers:
;	a, x, y
.export load_next_superblock
.proc load_next_superblock
	
	header_ptr = $0
	header_offset_hi = $2
	
	ldy #00                          ; set first block in superblock
	sty idx_block                    ;

	lda idx_superblock
	cmp num_sblk_headers             ; check if we're past the last superblock
	bne @continue
	;                                ; if so...
	sty idx_superblock               ; loop back to first superblock (y = 0)
	tya
@continue:                               ; (a = idx_superblock)
	;                                ; calculate header offset
	sty header_offset_hi             ; zero out high byte of offset (y = 0)
	
	asl a                            ; 16-bit multiply superblock index by 8
	rol header_offset_hi             ; shift 3 bits into high byte of offset
	asl a
	rol header_offset_hi
	asl a
	rol header_offset_hi
	
	clc
	ldx #<sblk_table                 ; load low byte of base ptr
	stx header_ptr
	adc header_ptr                   ; add low byte of offset to low byte of base ptr
	sta header_ptr
	lda #>sblk_table                 ; load high byte of base ptr
	adc header_offset_hi             ; add (with carry) high byte of offset to high byte of base ptr
	sta header_ptr + 1

	lda (header_ptr), y              ; bits_bank (y = 0)
	sta bits_bank
	
	iny                              ; (y = 1)
	lda (header_ptr), y              ; slopes_bank
	sta slopes_bank
	
	iny                              ; (y = 2)
	lda (header_ptr), y              ; bits (ptr low byte)
	sta ptr_bitstream
	iny                              ; (y = 3)
	lda (header_ptr), y              ; bits (ptr high byte)
	sta ptr_bitstream + 1
	
	iny                              ; (y = 4)
	lda (header_ptr), y              ; slopes (ptr low byte)
	sta ptr_slopes
	iny                              ; (y = 5)
	lda (header_ptr), y              ; slopes (ptr high byte)
	sta ptr_slopes + 1
	
	iny                              ; (y = 6)
	lda (header_ptr), y              ; initial_sample
	sta last_sample
	
	iny                              ; (y = 7)
	lda (header_ptr), y              ; length
	sta superblock_length
	
	rts
.endproc
