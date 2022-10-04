.include "playback.inc"

.globalzp tmp_addr, tmp_ret_addr, tmp_shortbuf
.globalzp idx_superblock, idx_block, idx_pcm_decode, idx_pcm_playback
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample, block_slope

.import sblk_headers, num_sblk_headers

.global buf_pcm
.global decode_byte_jump_tbl1_low, decode_byte_jump_tbl1_high
.global decode_byte_jump_tbl2_low, decode_byte_jump_tbl2_high

.segment "CODE"
.align 256
; Decodes a 128-sample block
; uses:
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
;	tmp_addr
;	tmp_ret_addr
;	tmp_bytes_left
.export decode_block
.export decode_byte_after1
.export decode_byte_after2
decode_block:                            ;     48

	ldy idx_block                    ;  3  51
	lda (ptr_slopes), y              ;  5  56   load slope value from block slopes array
	sta block_slope                  ;  3  59

	ldy #$00                         ;  2  61

	decode_byte:                               ;     61
		lda (ptr_bitstream), y             ;  5  66
		lsr a                              ;  2  68
		lsr a                              ;  2  70
		lsr a                              ;  2  72
		lsr a                              ;  2  74   extract upper nibble
		tax                                ;  2  76
		lda decode_byte_jump_tbl1_low, x   ;  4  80   fetch jump table address to decode this nibble
		sta tmp_addr                       ;  3  83
		lda decode_byte_jump_tbl1_high, x  ;  4  87
		sta a:tmp_addr + 1                 ;  3  91   using absolute addressing to waste 1 cycle here
		
		play_sample_inline_clobber_ax      ; 16  -7 - sample playback at 91 + 11 = 102
	
		lda last_sample                    ;  3  -4
		ldx idx_pcm_decode                 ;  3  -1
		jmp (tmp_addr)                     ;  5   4   decode nibble
		;                                  ; 51  55
	decode_byte_after1:
		sta last_sample                    ;  3  58
		stx idx_pcm_decode                 ;  3  61

		lda (ptr_bitstream), y             ;  5  66
		and #$0f                           ;  2  68   extract lower nibble
		tax                                ;  2  70
		lda decode_byte_jump_tbl2_low, x   ;  4  74   fetch jump table address to decode this nibble
		sta tmp_addr                       ;  3  77
		lda decode_byte_jump_tbl2_high, x  ;  4  81
		sta tmp_addr + 1                   ;  3  84
		iny                                ;  2  86
		
		play_sample_inline_late_clobber_ax ; 16 -12 - sample playback at 86 + 16 = 102
		
		lda last_sample                    ;  3  -9
		ldx idx_pcm_decode                 ;  3  -6
		jmp (tmp_addr)                     ;  5  -1   decode nibble
		;                                  ; 51  50
	decode_byte_after2:
		sta last_sample                    ;  3  53
		stx idx_pcm_decode                 ;  3  56
		
		cpy #16                            ;  2  58
		bne decode_byte                    ;  3  61
	
@after:                                  ; -1  60
	inc idx_block                    ;  5  65
	lda superblock_length            ;  3  68
	cmp idx_block                    ;  3  71   compare number of blocks played with length of superblock
	nop                              ;  2  73
	bne @align_update_ptr_bitstr     ;  2  75
	
	cmp idx_block                    ;  3  78   dummy
	nop                              ;  2  80
	inc idx_superblock               ;  5  85
	jsr load_next_superblock         ;  6  91
	;                                ;137   0   (91 + 137 - 114)
	rts                              ;  6   6
	
@align_update_ptr_bitstr:                        ;  1  76
	clc                                      ;  2  78
	lda ptr_bitstream                        ;  3  81
	adc #16                                  ;  2  83
	sta ptr_bitstream                        ;  3  86
	play_sample_inline_savecarry_clobber_axy ; 16  -7 - sample playback at 86 + 11 = 102
	bcc @nocarry                             ;  2  -5
	inc ptr_bitstream + 1                    ;  5   0
	rts                                      ;  6   6

@nocarry:                                ;  1  -4
	nop                              ;  2  -2
	nop                              ;  2   0
	rts                              ;  6   6


.segment "CODE"
; Loads the next superblock in the stream.
; If end of superblock list is reached, loops back to the beginning.
; uses:
;	idx_superblock
; updates:
;	idx_block
;	idx_superblock
;	superblock_length
;	ptr_bitstream
;	last_sample
; clobbers:
;	a, x, y
.export load_next_superblock
load_next_superblock:                    ;     91
	play_sample_inline_clobber_ax    ; 16  -7 - sample playback at 91 + 11 = 102
	lda idx_superblock               ;  3  -4
	cmp num_sblk_headers             ;  4   0   check if we reached the end of the superblock list
	bne @align_continue              ;  2   2   if not, keep going
	
	lda #00                          ;  2   4
	sta idx_superblock               ;  3   7
	jmp @continue                    ;  3  10
	
@align_continue:                         ;  1   3
	lda #00                          ;  2   5
	sta idx_block                    ;  3   8
	nop                              ;  2  10

@continue:                               ;     10
	sta idx_block                    ;  3  13

	lda idx_superblock               ;  3  16
	asl a                            ;  2  18
	asl a                            ;  2  20
	asl a                            ;  2  22   index into superblock header; headers start every 8 bytes
	tax                              ;  2  24

	lda sblk_headers+1, x            ;  4  28   load length of superblock (in blocks) from header
	sta superblock_length            ;  3  31

	lda sblk_headers+2, x            ;  4  35   copy pointer to bitstream start from superblock header
	sta ptr_bitstream                ;  3  38
	lda sblk_headers+2 + 1, x        ;  4  42
	sta ptr_bitstream + 1            ;  3  45
	
	lda sblk_headers+4, x            ;  4  49   copy pointer to block slope list from superblock header
	sta ptr_slopes                   ;  3  52
	lda sblk_headers+4 + 1, x        ;  4  56
	sta ptr_slopes + 1               ;  3  59
	
	lda sblk_headers+6, x            ;  4  63   load initial sample value from superblock header
	sta last_sample                  ;  3  66
	
	
	ldy #4                           ;  2  68   3 * 5 + 4 = 19
	@delay:                          ; 19  87
		dey
		bne @delay
	nop                               ;  2  89
	nop                               ;  2  91
	play_sample_inline_17c_clobber_ax ; 17  -6 - sample playback at 91 + 11 = 102
	
	rts                              ;  6   0
