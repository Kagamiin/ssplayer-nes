.ifndef __PLAY_SAMPLE_INC__
__PLAY_SAMPLE_INC__ = 1

.include "checked_branches.inc"

.macro play_sample_1
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	@delay_loop_1:
		sbc #1              ;  2
		c_bne @delay_loop_1 ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_1           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_2
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	@delay_loop_2:
		sbc #1              ;  2
		c_bne @delay_loop_2 ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_2           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_3
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	@delay_loop_3:
		sbc #1              ;  2
		c_bne @delay_loop_3 ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_3           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_4
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	@delay_loop_4:
		sbc #1              ;  2
		c_bne @delay_loop_4 ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_4           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro



.macro play_sample_1_comb
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	sbc #1                     ;  2  7
	@delay_loop_1:
		sbc #1              ;  2
		c_bne @delay_loop_1 ;  3
	;                          ; -6  1 + 5n

	lda tmp_sample_1           ;  3  4 + 5n
	adc tmp_sample_4_last      ;  3  7 + 5n
	lsr a                      ;  2  9 + 5n
	sta $4011                  ;  4 13 + 5n
.endmacro

.macro play_sample_2_comb
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	sbc #1                     ;  2  7
	@delay_loop_2:
		sbc #1              ;  2
		c_bne @delay_loop_2 ;  3
	;                          ; -6  1 + 5n

	lda tmp_sample_2           ;  3  4 + 5n
	adc tmp_sample_1           ;  3  7 + 5n
	lsr a                      ;  2  9 + 5n
	sta $4011                  ;  4 13 + 5n
.endmacro

.macro play_sample_3_comb
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	sbc #1                     ;  2  7
	@delay_loop_3:
		sbc #1              ;  2
		c_bne @delay_loop_3 ;  3
	;                          ; -6  1 + 5n

	lda tmp_sample_3           ;  3  4 + 5n
	adc tmp_sample_2           ;  3  7 + 5n
	lsr a                      ;  2  9 + 5n
	sta $4011                  ;  4 13 + 5n
.endmacro

.macro play_sample_4_comb
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	sbc #1                     ;  2  7
	@delay_loop_4:
		sbc #1              ;  2
		c_bne @delay_loop_4 ;  3
	;                          ; -6  1 + 5n

	lda tmp_sample_4           ;  3  4 + 5n
	sta tmp_sample_4_last      ;  3  7 + 5n
	adc tmp_sample_3           ;  3 10 + 5n
	lsr a                      ;  2 12 + 5n
	sta $4011                  ;  4 16 + 5n
.endmacro



.endif
