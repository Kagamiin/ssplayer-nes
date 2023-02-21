.include "smc.inc"
.include "nes_mmio.inc"
.include "checked_branches.inc"
.include "play_sample.inc"

.segment "DECODE"


; Decodes 32 bytes (128 samples) of 2-bit SSDPCM.
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
.export decode_play_sync
.proc decode_play_sync

	.globalzp bits_bank, slopes_bank
	.globalzp idx_block, idx_pcm_decode, idx_superblock
	.globalzp superblock_length, last_sample, ptr_bitstream, ptr_slopes
	.globalzp tmp_playback_a, playback_delay_count
	.globalzp mmc3_bank_select_shadow, mmc3_mutex

	.import load_next_superblock
	
	.import bank_numbers

	.global buf_pcm

	jmp_dst1 = $0
	jmp_dst2 = $2
	slope0   = $4
	slope1   = $5
	tmp_sample_1 = $6
	tmp_sample_2 = $7
	tmp_sample_3 = $8
	tmp_sample_4 = $9
	
	.macro play_sample_3_minus8
		lda playback_delay_count   ;  3  3
		sec                        ;  2  5
		sbc #2                     ;  2  7
		@delay_loop_3:
			sbc #1              ;  2
			c_bne @delay_loop_3 ;  3
		;                          ;-11 -4 + 5n

		lda tmp_sample_3           ;  3 -1 + 5n
		sta $4011                  ;  4  3 + 5n
	.endmacro
	
.segment "DECODE"

prepare:
	lda #>decode_unroll_1
	sta jmp_dst1+1
	lda #>decode_unroll_2
	sta jmp_dst2+1

	inc mmc3_mutex
	lda mmc3_bank_select_shadow
	and #%11100000
	ora #%110
	sta $8000

load_slopes:                        ;      7
	lda slopes_bank             ;  3  10
	sta $8001                   ;  4  14

	ldy #$00                    ;  2  16
	lda (ptr_slopes), y         ;  5  21
	sta slope0                  ;  3  24
	iny                         ;  2  26  y = 1
	lda (ptr_slopes), y         ;  5  31
	sta slope1                  ;  3  34
	
	lda bits_bank               ;  3  37
	sta $8001                   ;  4  41
	
	ldy #$00                    ;  2  43
	jmp decode_byte_entry       ;  3  46
	
	decode_byte_preamble:                       ;      7
		ldx #7                              ;  2   9
		@delay_loop:
			dex                         ;  2
			c_bne @delay_loop           ;  3
			;                           ; 34  43
		ldx $00                             ;  3  46  dummy
		play_sample_3                       ;     57 + 5n
		
		ldx #9                              ;  2   2
		@delay_loop_:
			dex                         ;  2
			c_bne @delay_loop_          ;  3
			;                           ; 44  46
	decode_byte_entry:
		play_sample_4                       ;     57 + 5n
			
	decode_byte:
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		tax                                 ;  2   7
		lda decode_byte_jump_tbl1_low, x    ;  4  11  fetch jump table address to decode nibble
		sta jmp_dst1                        ;  3  14
		
		lda last_sample                     ;  3  17  load temporary regs
		jmp (jmp_dst1)                      ;  5  22  jump to fetched address
		; --------------------------------- ; 19  41
	
	decode_byte_return_nibble1:
		nop                                 ;  2  43
		sta last_sample                     ;  3  46
		play_sample_1                       ;     57 + 5n
		
		lda (ptr_bitstream), y              ;  5   5  load byte in bitstream
		and #$0f                            ;  2   7  extract upper nibble
		tax                                 ;  2   9
		lda decode_byte_jump_tbl2_low, x    ;  4  13  fetch jump table address to decode nibble
		sta jmp_dst2                        ;  3  16
		
		lda last_sample                     ;  3  19  load temporary regs
		jmp (jmp_dst2)                      ;  5  24  jump to fetched address
		; --------------------------------- ; 19  43
		
	decode_byte_return_nibble2:
		sta last_sample                     ;  3  46
		play_sample_2                       ;     57 + 5n
		
		iny                                 ;  2   2
		cpy #32                             ;  2   4
		c_bne decode_byte_preamble          ;  3   7

after:
	; Bitstream pointer update           ; -1   6
	clc                                  ;  2   8
	lda ptr_bitstream                    ;  3  11
	adc #32                              ;  2  13
	sta ptr_bitstream                    ;  3  16
	c_bcc @nocarry                       ;  3  ..  19
	;                                    ; -1  18  ..
	inc ptr_bitstream + 1                ;  5  23  ..
	jmp carry_ptr_bitstream              ;  3  26  ..

@nocarry:
	inc idx_block                        ;  5  ..  24
	lda superblock_length                ;  3  ..  27
	cmp idx_block                        ;  3  ..  30  check if we need to load the next superblock
	c_bne slope_update                   ;  3  ..  33
        ;                                    ; -1  ..  32
	inc a:idx_superblock                 ;  6  ..  38
	nop                                  ;  2  ..  40
	nop                                  ;  2  ..  42
	nop                                  ;  2  ..  44
	nop                                  ;  2  ..  46
	play_sample_3                        ;         57 + 5n
	dec mmc3_mutex                       ;  5  ..   5
	jmp load_next_superblock             ;  3  ..   8  load next superblock

slope_update:                                ;     ..  33
	clc                                  ;  2  ..  35
	lda ptr_slopes                       ;  3  ..  38  update slope pointer
	adc #2                               ;  2  ..  40
	sta ptr_slopes                       ;  3  ..  43
	c_bcc nocarry_slope                  ;  3  ..  46       ..
	;                                    ; -1  ..  ..       45
	play_sample_3                        ;                  56 + 5n
	inc ptr_slopes + 1                   ;  5  ..  ..        4
	jmp load_slopes                      ;  3  ..  ..        7

nocarry_slope:                               ;     ..  46
	play_sample_3                        ;         57 + 5n
	nop                                  ;  2       2
	nop                                  ;  2       4
	jmp load_slopes                      ;  3       7
	
carry_ptr_bitstream:                         ;     26
	inc idx_block                        ;  5  31
	lda superblock_length                ;  3  34
	cmp idx_block                        ;  3  37  check if we need to load the next superblock
	x_bne slope_update_2                 ;  4  41  HACK: assuming branch crosses page boundary
        ;                                    ; -2  39
	inc idx_superblock                   ;  5  44
	nop                                  ;  2  46
	play_sample_3                        ;     57 + 5n
	dec mmc3_mutex                       ;  5   5
	jmp load_next_superblock             ;  3   8  load next superblock

slope_update_2:                              ;     41
	clc                                  ;  2  43
	lda ptr_slopes                       ;  3  46  update slope pointer
	adc #2                               ;  2  48
	sta ptr_slopes                       ;  3  51
	c_bcc nocarry_slope_2                ;  3  54       ..
	;                                    ; -1  ..       52
	play_sample_3_minus8                 ;              55 + 5n
	inc a:ptr_slopes + 1                 ;  6  ..        4
	jmp load_slopes                      ;  3  ..        7
	

nocarry_slope_2:                             ;     54
	play_sample_3_minus8                 ;     57 + 5n
	nop                                  ;  2   2
	nop                                  ;  2   4
	jmp load_slopes                      ;  3   7

	.macro adc_slope_id    idx
		adc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro sbc_slope_id    idx
		sbc .ident (.sprintf ("slope%x", (idx)))
	.endmacro

	.macro decode_internal    code, last_code
		
		.if code & $02
			sec                        ; 2  2
			sbc_slope_id (code & $01)  ; 3  5
		.else
			clc                        ; 2  2
			adc_slope_id (code & $01)  ; 3  5
		.endif
	.endmacro

	.macro decode_code_offs0    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_1                    ; 3  8
	.endmacro
	
	.macro decode_code_offs1    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_2                    ; 3  8
	.endmacro
	
	.macro decode_code_offs2    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_3                    ; 3  8
	.endmacro
	
	.macro decode_code_offs3    code, last_code
		decode_internal code, last_code     ; 5  5
		sta tmp_sample_4                    ; 3  8
	.endmacro

	.macro decode_nibble_ret1    nib
	.ident (.sprintf ("decode_nibble_ret1_%x", nib)):
		decode_code_offs0 (nib >> 2) & $03,                   ; 8  8
		decode_code_offs1 nib & $03,        (nib >> 2) & $03  ; 8 16
		jmp decode_byte_return_nibble1                        ; 3 19
	.endmacro
	
	.macro decode_nibble_ret2    nib
	.ident (.sprintf ("decode_nibble_ret2_%x", nib)):
		decode_code_offs2 (nib >> 2) & $03,                   ; 8  8
		decode_code_offs3 nib & $03,        (nib >> 2) & $03  ; 8 16
		jmp decode_byte_return_nibble2                        ; 3 19
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

