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
.import decode_play_sync
	jsr decode_play_sync
	jmp main_loop

.endproc

; ---------------------------------------------------------------------------
.segment "INIT"

; ---------------------------------------------------------------------------
.proc reset
.globalzp playback_delay_count
.import mapper_init
.import load_next_superblock
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

	jsr load_next_superblock     ; load first superblock
	jsr delay_frame              ; extra time for PPU warm-up
	
	lda #(92 - 57) / 5           ; 127 clock cycles per sample = ~14093 Hz
	;lda #(127 - 57) / 5           ; 127 clock cycles per sample = ~14093 Hz
	sta playback_delay_count
	
	lda #$ff
	sta buf_vram_write           ; put terminator in VRAM write buffer
	
	lda #%00001010
	sta PPUMASK                  ; setup PPUMASK, enable background rendering
	sta ppumask_shadow
	
	;lda #%10001000
	lda #%00001000
	sta PPUCTRL                  ; setup PPUCTRL, don't enable NMI
	sta ppuctrl_shadow
	
	jmp main_loop
.endproc

.proc irq_trap
.global ppuctrl_shadow
	lda ppuctrl_shadow
	and #%01111111
	sta PPUCTRL                  ; disable NMI if enabled
	@infinite:
		jmp @infinite        ; infinite loop
.endproc

; ---------------------------------------------------------------------------
.segment "VECTORS"

.import nmi
.import irq_sample_selfmod

	.addr nmi                ; nmi
	.addr reset              ; reset
	.addr irq_trap           ; irq

