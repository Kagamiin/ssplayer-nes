.include "smc.inc"
.include "nes_mmio.inc"
.include "delays.inc"

.segment "HEADER"

.import INES_MAPPER, NES2_SUBMAPPER, NES2_BATTERY
.import INES_MIRROR, INES_CHR_BANKS, INES_PRG_BANKS
.import NES2_PRG_RAM_SHIFT, NES2_PRG_NVRAM_SHIFT
.import NES2_CHR_RAM_SHIFT, NES2_CHR_NVRAM_SHIFT
.import NES2_CPU_TIMING

	.byte 'N', 'E', 'S', $1A                                      ; 0..3: ID
	.byte <INES_PRG_BANKS                                         ; 4: 16k PRG chunk count
	.byte <INES_CHR_BANKS                                         ; 5: 8k CHR chunk count
	.byte <INES_MIRROR | (<NES2_BATTERY << 1) | ((<INES_MAPPER & $f) << 4) ; 6: mirroring and mapper LSN
	.byte (<INES_MAPPER & %11110000) | (%1000)                    ; 7: mapper MSN and NES 2.0 identifier
	.byte (>INES_MAPPER & $f) | ((<NES2_SUBMAPPER & $f) << 4)     ; 8: mapper MSB and submapper
	.byte (>INES_PRG_BANKS & $f) | ((>INES_CHR_BANKS & $f) << 4)  ; 9: PRG/CHR chunk count MSB
	.byte (<NES2_PRG_RAM_SHIFT & $f) | ((<NES2_PRG_NVRAM_SHIFT & $f) << 4) ; 10: PRG-RAM/NVRAM size
	.byte (<NES2_CHR_RAM_SHIFT & $f) | ((<NES2_CHR_NVRAM_SHIFT & $f) << 4) ; 11: CHR-RAM/NVRAM size
	.byte (<NES2_CPU_TIMING & $3)                                 ; 12: intended CPU type/timing

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
;.globalzp nmi_triggered
.import mapper_init
.import load_next_superblock
.import load_decoder
;.import load_graphics
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

.ifdef SOFTRATE
	jsr load_decoder
.endif

	jsr load_next_superblock     ; load first superblock
	jsr delay_frame              ; extra time for PPU warm-up
	
	;lda #(92 - 57) / 5            ; 127 clock cycles per sample = ~19454 Hz
	lda #(112 - 57) / 5           ; 112 clock cycles per sample = ~15980 Hz
	;lda #(127 - 57) / 5           ; 127 clock cycles per sample = ~14093 Hz
	sta playback_delay_count
	
	lda #$ff
	sta buf_vram_write           ; put terminator in VRAM write buffer
	
	;lda #%00001010               ; setup PPUMASK
	lda #%00000000               ; setup PPUMASK, disable all rendering
	sta PPUMASK
	sta ppumask_shadow
	
	;jsr load_graphics

	;lda #%10101000               ; use 8x16 objects, enable NMI
	lda #%00101000               ; don't enable NMI
	sta PPUCTRL                  ; setup PPUCTRL
	sta ppuctrl_shadow
	
	;@wait:
	;	lda nmi_triggered
	;	beq @wait
	
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

