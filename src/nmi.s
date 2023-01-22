.include "smc.inc"
.include "nes_mmio.inc"
.include "delays.inc"

; ---------------------------------------------------------------------------
.segment "MAIN"

; ---------------------------------------------------------------------------
.export nmi
.proc nmi
.globalzp nmi_semaph, irq_latch_value
.global oam_dma_enable, oam_dma_sample_skip_cnt
.import fill_buffer

SMC_Import idx_smc_pcm_playback

	pha
	
	lda nmi_semaph                 ; check NMI semaphore
	beq @continue
	
	pla
	rti                            ; reentrant call, bail out
	
@continue:
	inc nmi_semaph                 ; take NMI semaphore
	
	txa
	pha
	tya
	pha

	lda oam_dma_enable
	beq @after_oam_dma

	lda #$02
	sta OAMDMA                     ; trigger OAM DMA - 513/514 cycles
	
	SMC_LoadLowByte idx_smc_pcm_playback, a
	clc
	adc oam_dma_sample_skip_cnt    ; skip over lost samples during OAM DMA
	SMC_StoreLowByte idx_smc_pcm_playback, a
	
@after_oam_dma:
	cli                            ; enable interrupts, so samples can be played
	
	jsr delay_1536                 ; wait approximately until the start of the frame
	jsr fill_buffer                ; fill PCM buffer here
	
	lda #0
	sta nmi_semaph                 ; release NMI semaphore
	
	pla
	tay
	pla
	tax
	
	pla
	rti
.endproc
