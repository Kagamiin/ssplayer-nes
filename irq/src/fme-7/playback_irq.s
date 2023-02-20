.include "smc.inc"


.segment "PLAYBACK_CODE"

.export irq_sample_selfmod
; ---------------------------------------------------------------------------
.proc irq_sample_selfmod              ;    7
.globalzp tmp_irq_a, irq_period_holder
.global buf_pcm
.import nmi
	sta tmp_irq_a                 ; 3 10
	lda #$0d                      ; 2 12  command $d - IRQ control
	sta $8000                     ; 4 16
	lda #$81                      ; 2 18
	sta $a000                     ; 4 22  acknowledge IRQ, while keeping it enabled
	
	lda #$e                       ; 2 24  command $e - IRQ counter low byte
	sta $8000                     ; 4 28
	lda irq_period_holder         ; 3 31
	sta $a000                     ; 4 35  retrigger IRQ
	
	lda #$f                       ; 2 37
	sta $8000                     ; 4 41  command $f - IRQ counter high byte
	lda #$00                      ; 2 43
	sta $a000                     ; 4 47
	
	SMC sample_addr_offset, { lda buf_pcm }
	;                             ; 4 51
	sta $4011                     ; 4 55
	SMC_OperateOnLowByte    inc, sample_addr_offset
	lda tmp_irq_a                 ; 3 58
	rti                           ; 6 64
	
.endproc
SMC_Export idx_smc_pcm_playback, irq_sample_selfmod::sample_addr_offset

