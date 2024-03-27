.ifndef __PLAY_SAMPLE_INC__
__PLAY_SAMPLE_INC__ = 1

.include "checked_branches.inc"

.macro play_sample_1
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_1           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_2
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_2           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_3
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_3           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_4
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_4           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro

.macro play_sample_5
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -1  4 + 5n

	lda tmp_sample_5           ;  3  7 + 5n
	sta $4011                  ;  4 11 + 5n
.endmacro


.macro play_sample_1_comb
	lda playback_delay_count   ;  3  3
	sec                        ;  2  5
	sbc #1                     ;  2  7
	:
		sbc #1              ;  2
		c_bne :-            ;  3
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
	:
		sbc #1              ;  2
		c_bne :-            ;  3
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
	:
		sbc #1              ;  2
		c_bne :-            ;  3
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
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6  1 + 5n

	lda tmp_sample_4           ;  3  4 + 5n
	sta tmp_sample_4_last      ;  3  7 + 5n
	adc tmp_sample_3           ;  3 10 + 5n
	lsr a                      ;  2 12 + 5n
	sta $4011                  ;  4 16 + 5n
.endmacro

.macro play_sample_1_softrate
	nop                        ;  2  2
	nop                        ;  2  4
	nop                        ;  2  6
	nop                        ;  2  8
	lda a:playback_delay_count ;  4 12
	sec                        ;  2 14
	sbc #2                     ;  2 16
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                         ; -11  5 + 5n, n >= 3

	lda tmp_sample_1           ;  3  8 + 5n
	sta $4011                  ;  4 12 + 5n
.endmacro

.macro play_sample_2_softrate
	nop                        ;  2  2
	nop                        ;  2  4
	nop                        ;  2  6
	nop                        ;  2  8
	lda a:playback_delay_count ;  4 12
	sec                        ;  2 14
	sbc #2                     ;  2 16
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                         ; -11  5 + 5n, n >= 3

	lda tmp_sample_2           ;  3  8 + 5n
	sta $4011                  ;  4 12 + 5n
.endmacro

.macro play_sample_3_softrate
	nop                        ;  2  2
	nop                        ;  2  4
	nop                        ;  2  6
	nop                        ;  2  8
	lda a:playback_delay_count ;  4 12
	sec                        ;  2 14
	sbc #2                     ;  2 16
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                         ; -11  5 + 5n, n >= 3

	lda tmp_sample_3           ;  3  8 + 5n
	sta $4011                  ;  4 12 + 5n
.endmacro

.macro play_sample_4_softrate
	nop                        ;  2  2
	nop                        ;  2  4
	nop                        ;  2  6
	nop                        ;  2  8
	lda a:playback_delay_count ;  4 12
	sec                        ;  2 14
	sbc #2                     ;  2 16
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                         ; -11  5 + 5n, n >= 3

	lda tmp_sample_4           ;  3  8 + 5n
	sta $4011                  ;  4 12 + 5n
.endmacro

.macro play_sample_5_softrate
	nop                        ;  2  2
	nop                        ;  2  4
	nop                        ;  2  6
	nop                        ;  2  8
	lda a:playback_delay_count ;  4 12
	sec                        ;  2 14
	sbc #2                     ;  2 16
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                         ; -11  5 + 5n, n >= 3

	lda tmp_sample_5           ;  3  8 + 5n
	sta $4011                  ;  4 12 + 5n
.endmacro

.endif
