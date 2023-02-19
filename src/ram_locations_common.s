
.segment "ZEROPAGE"

	; ---------------------
	; SSDPCM decoder
	; ---------------------
	
.globalzp idx_superblock, idx_block, idx_pcm_decode
	idx_superblock:       .res 1  ; index of currently-playing superblock
	idx_block:            .res 1  ; index of block in superblock
	idx_pcm_decode:       .res 1  ; index of next sample to be overwritten by the decoder

.globalzp bits_bank, slopes_bank
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample
	bits_bank:            .res 1  ; bank containing the current block's bitstream
	slopes_bank:          .res 1  ; bank containing the current block's slopes
	ptr_bitstream:        .res 2  ; pointer to position in bitstream
	ptr_slopes:           .res 2  ; pointer to slope list for this block
	superblock_length:    .res 1  ; length of current superblock in blocks
	last_sample:          .res 1  ; value of the last sample, used by the decode routine
	
	; ---------------------
	; Sample playback IRQ
	; ---------------------
	
.globalzp tmp_irq_a, irq_latch_value
	tmp_irq_a:            .res 1  ; temporary location for IRQ routine to save the "a" register
	irq_latch_value:      .res 1  ; value written to the IRQ latch, determines the sample rate
	
	; ---------------------
	; NMI
	; ---------------------
	
.globalzp nmi_triggered
	nmi_triggered:        .res 1  ; signals whether NMI has been fired



.segment "BSS"
	; ---------------------
	; NMI
	; ---------------------
	
.export oam_dma_enable, oam_dma_sample_skip_cnt
	oam_dma_enable:            .res 1  ; enable OAM DMA during NMI (slight drop in sound quality)
	oam_dma_sample_skip_cnt:   .res 1  ; number of playback samples to skip ahead to compensate
	;                                  ; for lost sample playback time during OAM DMA
	
	; --------------------
	; Global
	; --------------------
	
.global ppuctrl_shadow, ppumask_shadow
	ppuctrl_shadow:            .res 1  ; Stores the value of PPUCTRL, for bit modification
	ppumask_shadow:            .res 1  ; Stores the value of PPUMASK, for bit modification

	; --------------------
	; VRAM writer
	; --------------------

.global screen_copy_offset
	screen_copy_offset:     .res 2

; ---------------------------------------------
; Space reservations for non-allocatable areas
; ---------------------------------------------

.segment "SHORTRAM"
.global buf_vram_write
	slack: .res 6
	buf_vram_write:

.segment "OAM"
	buf_oam: .res 256

.segment "SAMPLE_BUF"
.global buf_pcm
	buf_pcm: .res 256
