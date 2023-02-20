
; ----------------------------------------------------------------------------
;  Original ~15700 Hz playback routine, without comb filter
; ----------------------------------------------------------------------------
; play_sample_inline_*_clobber_ax:
; Plays a single sample from the decoded buffer.
; uses:
;	idx_pcm_playback
; updates:
;	idx_pcm_playback
; clobbers:
;	a, x

.macro play_sample_inline_clobber_ax ; 16 cycles; sample is played at 11 cycles in - start 91, exit -7
	ldx idx_pcm_playback ;  3  3
	lda buf_pcm, x       ;  4  7
	sta $4011            ;  4 11
	inc idx_pcm_playback ;  5 16
.endmacro

.macro play_sample_inline_savecarry_clobber_axy ; 21 cycles; sample is played at 16 cycles in - start 86, exit -7
	                                        ; does not affect carry in the first place; does not actually clobber y
	nop                  ;  2  2
	ldx idx_pcm_playback ;  3  5
	ldx idx_pcm_playback ;  3  8   dummy
	lda buf_pcm, x       ;  4 12
	sta $4011            ;  4 16
	inc idx_pcm_playback ;  5 21
.endmacro

.macro play_sample_inline_late_clobber_ax ; 16 cycles; sample is played at 16 cycles in - start 86, exit -12
	ldx idx_pcm_playback ;  3  3
	lda buf_pcm, x       ;  4  7
	inc idx_pcm_playback ;  5 12
	sta $4011            ;  4 16
.endmacro

.macro play_sample_inline_17c_clobber_ax ; 17 cycles; sample is played at 11 cycles in - start 91, exit -6
	ldx idx_pcm_playback   ;  3  3
	lda buf_pcm, x         ;  4  7
	sta $4011              ;  4 11
	inc a:idx_pcm_playback ;  6 17
.endmacro
