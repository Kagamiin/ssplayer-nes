.include "smc.inc"

.segment "PLAYBACK_CODE"

.export irq_sample_selfmod
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod              ;    7
.globalzp tmp_irq_a
.global buf_pcm
	sta tmp_irq_a                 ; 3 10
	sta $f010                     ; 4 14
	SMC sample_addr_offset, { lda buf_pcm }
	;                             ; 4 18
	sta $4011                     ; 4 22
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 28
	lda tmp_irq_a                 ; 3 31
	rti                           ; 6 37
.endproc
SMC_Export idx_smc_pcm_playback, irq_sample_selfmod::sample_addr_offset
