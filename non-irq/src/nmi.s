.include "smc.inc"
.include "nes_mmio.inc"
.include "delays.inc"

; ---------------------------------------------------------------------------
.segment "MAIN"

; ---------------------------------------------------------------------------
.export nmi
.proc nmi
.globalzp nmi_triggered
.global ppuctrl_shadow
.global ppumask_shadow
	pha
	
	lda #$02
	sta OAMDMA                     ; trigger OAM DMA - 513/514 cycles
	lda PPUSTATUS
	lda #$00
	sta PPUSCROLL                  ; reset scroll
	sta PPUSCROLL
	
	lda ppuctrl_shadow
	and #%01111111                 ; disable NMI generation
	sta PPUCTRL
	sta ppuctrl_shadow
	
	lda ppumask_shadow
	ora #%00011110                 ; enable background and sprite rendering, including leftmost 8 pixels
	sta PPUMASK
	sta ppumask_shadow
	
	pla
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
