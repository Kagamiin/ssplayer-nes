.include "smc.inc"
.include "nes_mmio.inc"
.include "delays.inc"

.segment "HEADER"

.import INES_MAPPER, INES_SRAM, INES_MIRROR, INES_CHR_BANKS, INES_PRG_BANKS

	.byte 'N', 'E', 'S', $1A ; ID
	.byte <INES_PRG_BANKS ; 16k PRG chunk count
	.byte <INES_CHR_BANKS ; 8k CHR chunk count
	.byte <INES_MIRROR | (<INES_SRAM << 1) | ((<INES_MAPPER & $f) << 4)
	.byte (INES_MAPPER & %11110000)
	.byte $0, $0, $0, $0, $0, $0, $0, $0 ; padding

; ---------------------------------------------------------------------------
.segment "MAIN"

; ---------------------------------------------------------------------------
.proc main_loop
.globalzp nmi_triggered
.import vblank
.import copy_screen
	lda nmi_triggered
	beq main_loop
	jsr vblank
	jsr copy_screen
	jmp main_loop

.endproc

; ---------------------------------------------------------------------------
.segment "INIT"

; ---------------------------------------------------------------------------
.proc load_playback_code
.import __PLAYBACK_CODE_LOAD__, __PLAYBACK_CODE_RUN__, __PLAYBACK_CODE_SIZE__
	ldx #<__PLAYBACK_CODE_SIZE__
	@loop:
		dex
		lda __PLAYBACK_CODE_LOAD__, x
		sta __PLAYBACK_CODE_RUN__, x
		cpx #00
		bne @loop
	rts

.assert __PLAYBACK_CODE_SIZE__ <= 256, error, "playback code is bigger than 256 bytes"
.endproc


; ---------------------------------------------------------------------------
.proc reset
.globalzp irq_latch_value
.import mapper_init, mapper_irq_set_period, mapper_irq_disable, mapper_irq_enable
.import decode_async, load_next_superblock
.global oam_dma_enable, oam_dma_sample_skip_cnt
.global ppuctrl_shadow, ppumask_shadow, buf_vram_write

	jsr mapper_init
	ldx #$ff
	stx $4017                    ; disable frame counter IRQ
	txs
	
	; clear memory
	; we cannot use the stack here since it'll be cleared, so we're inlining this code
	ldx #7
	lda #0
	sta $0                       ; base address low byte = 0
	tay                          ; y = 0
	@loop:
		stx $1               ; base address = page to be cleared
		@inner:              ; y underflows from 0 to ff
			dey
			sta ($0), y
			bne @inner   ; clears all ram from $ff to $00 in the current page
		dex
		bpl @loop            ; clears pages 7 to 0


	jsr load_playback_code       ; copy playback code into RAM
	jsr load_next_superblock     ; load first superblock
	jsr decode_async         ; pre-fill the buffer with some samples
	jsr decode_async
	jsr decode_async
	
	jsr delay_frame              ; extra time for PPU warm-up
	
	lda #(256 - 127)             ; 127 clock cycles per sample = ~14093 Hz
	sta irq_latch_value
	jsr mapper_irq_set_period
	jsr mapper_irq_enable
	cli                          ; enable interrupts, so samples can play
	
	lda #4
	sta oam_dma_sample_skip_cnt  ; setup flags to enable OAM DMA
	sta oam_dma_enable
	
	lda #$ff
	sta buf_vram_write           ; put terminator in VRAM write buffer
	
	lda #%00001010
	sta PPUMASK                  ; setup PPUMASK, enable background rendering
	sta ppumask_shadow
	
	lda #%10001000
	sta PPUCTRL                  ; setup PPUCTRL, enable NMI
	sta ppuctrl_shadow
	
	jmp main_loop
.endproc

; ---------------------------------------------------------------------------
.segment "VECTORS"

.import nmi
.import irq_sample_selfmod

	.addr nmi                ; nmi
	.addr reset              ; reset
	.addr irq_sample_selfmod ; irq

