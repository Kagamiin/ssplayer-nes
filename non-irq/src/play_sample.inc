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
	lda tmp_delay_count        ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6 -1 + 5n, n >= 2

	c_beq :+                   ;  3  2
	.byte $c9 ; cmp #$c9       ;  2  4
	cmp #$c9                    ; 2  :  4
	;           cmp #$c9       ;  2  6  :  4
	cmp #$c5                    ; 2  :  6  :  4
:       ;           cmp $ea        ;  3  9  :  7  ;  5
	nop                         ; 2  '  8  '  6  '  4

	;                          ;     4 + 5n + f
	lda tmp_sample_1           ;  3  7 + 5n + f
	sta $4011                  ;  4 11 + 5n + f
.endmacro

.macro play_sample_2_softrate
	lda tmp_delay_count        ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6 -1 + 5n, n >= 2

	c_beq :+                   ;  3  2
	.byte $c9 ; cmp #$c9       ;  2  4
	cmp #$c9                    ; 2  :  4
	;           cmp #$c9       ;  2  6  :  4
	cmp #$c5                    ; 2  :  6  :  4
:       ;           cmp $ea        ;  3  9  :  7  ;  5
	nop                         ; 2  '  8  '  6  '  4

	;                          ;     4 + 5n + f
	lda tmp_sample_2           ;  3  7 + 5n + f
	sta $4011                  ;  4 11 + 5n + f
.endmacro

.macro play_sample_3_softrate
	lda tmp_delay_count        ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6 -1 + 5n, n >= 2

	c_beq :+                   ;  3  2
	.byte $c9 ; cmp #$c9       ;  2  4
	cmp #$c9                    ; 2  :  4
	;           cmp #$c9       ;  2  6  :  4
	cmp #$c5                    ; 2  :  6  :  4
:       ;           cmp $ea        ;  3  9  :  7  ;  5
	nop                         ; 2  '  8  '  6  '  4

	;                          ;     4 + 5n + f
	lda tmp_sample_3           ;  3  7 + 5n + f
	sta $4011                  ;  4 11 + 5n + f
.endmacro

.macro play_sample_4_softrate
	lda tmp_delay_count        ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6 -1 + 5n, n >= 2

	c_beq :+                   ;  3  2
	.byte $c9 ; cmp #$c9       ;  2  4
	cmp #$c9                    ; 2  :  4
	;           cmp #$c9       ;  2  6  :  4
	cmp #$c5                    ; 2  :  6  :  4
:       ;           cmp $ea        ;  3  9  :  7  ;  5
	nop                         ; 2  '  8  '  6  '  4

	;                          ;     4 + 5n + f
	lda tmp_sample_4           ;  3  7 + 5n + f
	sta $4011                  ;  4 11 + 5n + f
.endmacro

.macro play_sample_5_softrate
	lda tmp_delay_count        ;  3  3
	sec                        ;  2  5
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ; -6 -1 + 5n, n >= 2

	c_beq :+                   ;  3  2
	.byte $c9 ; cmp #$c9       ;  2  4
	cmp #$c9                    ; 2  :  4
	;           cmp #$c9       ;  2  6  :  4
	cmp #$c5                    ; 2  :  6  :  4
:       ;           cmp $ea        ;  3  9  :  7  ;  5
	nop                         ; 2  '  8  '  6  '  4

	;                          ;     4 + 5n + f
	lda tmp_sample_5           ;  3  7 + 5n + f
	sta $4011                  ;  4 11 + 5n + f
.endmacro

.macro play_sample_1_comb_softrate
	lda tmp_delay_count        ;  3  3
	c_beq :++                  ;  3  .        6
	;                          ; -1  5
	sec                        ;  2  7
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ;-11 -4 + 5n,      n >= 3
	:                          ;    -4 + 5n = 6;  n == 2

	c_beq :+                   ;  3 -1
	.byte $c9 ; cmp #$c9       ;  2  1
	cmp #$c9                    ; 2  :  1
	;           cmp #$c9       ;  2  3  :  1
	cmp #$c5                    ; 2  :  3  :  1
:       ;           cmp $ea        ;  3  6  :  4  ;  2
	nop                         ; 2  '  5  '  3  '  1

	;                          ;     1 + 5n + f
	lda tmp_sample_1           ;  3  4 + 5n + f
	adc tmp_sample_4_last      ;  3  7 + 5n + f
	lsr a                      ;  2  9 + 5n + f
	sta $4011                  ;  4 13 + 5n + f
.endmacro

.macro play_sample_2_comb_softrate
	lda tmp_delay_count        ;  3  3
	c_beq :++                  ;  3  .        6
	;                          ; -1  5
	sec                        ;  2  7
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ;-11 -4 + 5n,      n >= 3
	:                          ;    -4 + 5n = 6;  n == 2

	c_beq :+                   ;  3 -1
	.byte $c9 ; cmp #$c9       ;  2  1
	cmp #$c9                    ; 2  :  1
	;           cmp #$c9       ;  2  3  :  1
	cmp #$c5                    ; 2  :  3  :  1
:       ;           cmp $ea        ;  3  6  :  4  ;  2
	nop                         ; 2  '  5  '  3  '  1

	;                          ;     1 + 5n + f
	lda tmp_sample_2           ;  3  4 + 5n + f
	adc tmp_sample_1           ;  3  7 + 5n + f
	lsr a                      ;  2  9 + 5n + f
	sta $4011                  ;  4 13 + 5n + f
.endmacro

.macro play_sample_3_comb_softrate
	lda tmp_delay_count        ;  3  3
	c_beq :++                  ;  3  .        6
	;                          ; -1  5
	sec                        ;  2  7
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ;-11 -4 + 5n,      n >= 3
	:                          ;    -4 + 5n = 6;  n == 2

	c_beq :+                   ;  3 -1
	.byte $c9 ; cmp #$c9       ;  2  1
	cmp #$c9                    ; 2  :  1
	;           cmp #$c9       ;  2  3  :  1
	cmp #$c5                    ; 2  :  3  :  1
:       ;           cmp $ea        ;  3  6  :  4  ;  2
	nop                         ; 2  '  5  '  3  '  1

	;                          ;     1 + 5n + f
	lda tmp_sample_3           ;  3  4 + 5n + f
	adc tmp_sample_2           ;  3  7 + 5n + f
	lsr a                      ;  2  9 + 5n + f
	sta $4011                  ;  4 13 + 5n + f
.endmacro

.macro play_sample_4_comb_softrate
	lda tmp_delay_count        ;  3  3
	c_beq :++                  ;  3  .        6
	;                          ; -1  5
	sec                        ;  2  7
	:
		sbc #1              ;  2
		c_bne :-            ;  3
	;                          ;-11 -4 + 5n,      n >= 3
	:                          ;    -4 + 5n = 6;  n == 2

	c_beq :+                   ;  3 -1
	.byte $c9 ; cmp #$c9       ;  2  1
	cmp #$c9                    ; 2  :  1
	;           cmp #$c9       ;  2  3  :  1
	cmp #$c5                    ; 2  :  3  :  1
:       ;           cmp $ea        ;  3  6  :  4  ;  2
	nop                         ; 2  '  5  '  3  '  1

	;                          ;     1 + 5n + f
	lda tmp_sample_4           ;  3  4 + 5n + f
	sta tmp_sample_4_last      ;  3  7 + 5n + f
	adc tmp_sample_3           ;  3 10 + 5n + f
	lsr a                      ;  2 12 + 5n + f
	sta $4011                  ;  4 16 + 5n + f
.endmacro

.endif
