
; ----------------------------------------------------------------------------
;  Modified ~13983 Hz playback routine, with comb filter
; ----------------------------------------------------------------------------
; play_sample_inline_*_clobber_ax:
; Plays a single sample from the decoded buffer.
; uses:
;	idx_pcm_playback
; updates:
;	idx_pcm_playback
; clobbers:
;	a, x, carry

.macro play_sample_inline_clobber_ax ; 30 cycles; sample is played at 25 cycles in - start 91, exit -7
	ldx idx_pcm_playback ;  3  3
	lda buf_pcm, x       ;  4  7
	sta a:tmp_shortbuf   ;  4 11   buffer read sample in case it's needed (for savecarry version)
	dex                  ;  2 13
	clc                  ;  2 15
	adc buf_pcm, x       ;  4 19   average with previous sample
	lsr a                ;  2 21
	sta $4011            ;  4 25
	inc idx_pcm_playback ;  5 30
.endmacro

.macro play_sample_inline_savecarry_clobber_axy ; 35 cycles; sample is played at 30 cycles in - start 86, exit -7
	                                        ; uses tmp_shortbuf, cannot be used twice in a row! clobbers y
	lda #$00             ;  2  2
	rol a                ;  2  4   shift carry out
	tay                  ;  2  6   save in y
	ldx idx_pcm_playback ;  3  9
	lda buf_pcm, x       ;  4 13
	adc tmp_shortbuf     ;  3 16   average with previous sample (buffered)
	lsr a                ;  2 18
	tax                  ;  2 20   save combed sample in x
	tya                  ;  2 22   recover saved carry word from y
	ror a                ;  2 24   shift carry back in
	txa                  ;  2 26   recover combed sample
	sta $4011            ;  4 30
	inc idx_pcm_playback ;  5 35
.endmacro

.macro play_sample_inline_late_clobber_ax ; 30 cycles; sample is played at 30 cycles in - start 86, exit -12
	ldx idx_pcm_playback ;  3  3
	lda buf_pcm, x       ;  4  7
	sta a:tmp_shortbuf   ;  4 11
	dex                  ;  2 13
	clc                  ;  2 15
	adc buf_pcm, x       ;  4 19
	lsr a                ;  2 21
	inc idx_pcm_playback ;  5 26
	sta $4011            ;  4 30
.endmacro

.macro play_sample_inline_17c_clobber_ax ; 31 cycles; sample is played at 25 cycles in - start 91, exit -6
	ldx idx_pcm_playback   ;  3  3
	lda buf_pcm, x         ;  4  7
	sta a:tmp_shortbuf     ;  4 11
	dex                    ;  2 13
	clc                    ;  2 15
	adc buf_pcm, x         ;  4 19
	lsr a                  ;  2 21
	sta $4011              ;  4 25
	inc a:idx_pcm_playback ;  6 31
.endmacro
