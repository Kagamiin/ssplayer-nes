.include "smc.inc"
.include "nes_mmio.inc"
.include "delays.inc"

; ---------------------------------------------------------------------------
.segment "MAIN"

; ---------------------------------------------------------------------------
.export nmi
.proc nmi
.globalzp nmi_triggered
	inc nmi_triggered
	rti

.endproc

; ---------------------------------------------------------------------------
.export vblank
.proc vblank
.globalzp nmi_triggered
.global oam_dma_enable

	lda oam_dma_enable
	beq @after_oam_dma

	lda #$02
	sta OAMDMA                     ; trigger OAM DMA - 513/514 cycles
	
@after_oam_dma:
	cli                            ; enable interrupts, so samples can be played

	lda PPUSTATUS
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL
	
	lda #$00
	sta nmi_triggered
	rts
.endproc
