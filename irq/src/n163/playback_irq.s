.include "smc.inc"


.segment "PLAYBACK_CODE"

.export irq_sample_selfmod
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod              ;    7
.globalzp tmp_irq_a, irq_period_holder
.global buf_pcm
	sta tmp_irq_a                 ; 3 10
	lda irq_period_holder         ; 3 13
	sta $5000                     ; 4 17  retrigger IRQ
	SMC sample_addr_offset, { lda buf_pcm }
	;                             ; 4 21
	sta $4011                     ; 4 25
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 31
	lda tmp_irq_a                 ; 3 34
	rti                           ; 6 40
.endproc
SMC_Export idx_smc_pcm_playback, irq_sample_selfmod::sample_addr_offset

