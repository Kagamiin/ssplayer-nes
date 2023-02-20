
.segment "DECODE"

; Loads the next superblock in the stream.
; If end of superblock list is reached, loops back to the beginning.
; uses:
;	idx_superblock
; updates:
;	idx_superblock
;	idx_block
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

	.globalzp idx_superblock, idx_block
	.globalzp bits_bank, slopes_bank
	.globalzp ptr_bitstream, ptr_slopes, last_sample, superblock_length

	.import sblk_table, num_sblk_headers
	.import mapper_set_bank_8000

	header_ptr = $0
	header_offset_hi = $2


	ldy #00                          ; set first block in superblock
	sty idx_block                    ;

	lda idx_superblock
	cmp num_sblk_headers             ; check if we're past the last superblock
	bmi @continue
	;                                ; if so...
	sty idx_superblock               ; loop back to first superblock (y = 0)
	tya
@continue:                               ; (a = idx_superblock)
	
	; Superblocks are stored as an array of structs of length 8.
	; Up to 256 superblock entries may be stored in the array.
	; Therefore we need to index into the array using a 16-bit offset.
	
	;                                ; calculate header offset
	sty header_offset_hi             ; zero out high byte of offset (y = 0)
	
	asl a                            ; 16-bit multiply superblock index by 8
	rol header_offset_hi             ; shift 3 bits into high byte of offset
	asl a
	rol header_offset_hi
	asl a
	rol header_offset_hi
	
	clc
	ldx #<sblk_table                 ; load low byte of superblock table base ptr
	stx header_ptr
	adc header_ptr                   ; add low byte of offset to low byte of base ptr
	sta header_ptr
	lda #>sblk_table                 ; load high byte of superblock table base ptr
	adc header_offset_hi             ; add (with carry) high byte of offset to high byte of base ptr
	sta header_ptr + 1

	; Read out superblock struct values into global variables for sample decode routine
	
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
