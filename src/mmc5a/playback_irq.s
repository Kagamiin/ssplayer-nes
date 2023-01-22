.include "smc.inc"


.segment "PLAYBACK_CODE"

.export irq_sample_selfmod
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod              ;    7
.globalzp tmp_irq_a, irq_period_holder
.global buf_pcm
	sta tmp_irq_a                 ; 3 10
	lda $5209                     ; 4 14  acknowledge IRQ
	lda irq_period_holder         ; 3 17
	sta $5209                     ; 4 21  retrigger IRQ
	SMC sample_addr_offset, { lda buf_pcm }
	;                             ; 4 25
	sta $4011                     ; 4 29
	SMC_OperateOnLowByte    inc, sample_addr_offset
	;                             ; 6 35
	lda tmp_irq_a                 ; 3 38
	rti                           ; 6 44
.endproc
SMC_Export idx_smc_pcm_playback, irq_sample_selfmod::sample_addr_offset

