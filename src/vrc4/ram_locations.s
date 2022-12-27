
.segment "ZEROPAGE"
	.org $00   ; ensure we're at the start of zeropage
	.res 16    ; temporaries $0..$f

	; ---------------------
	; SSDPCM decoder
	; ---------------------
	idx_superblock:       .res 1  ; index of currently-playing superblock
	idx_block:            .res 1  ; index of block in superblock
	idx_pcm_decode:       .res 1  ; index of next sample to be overwritten by the decoder

	bits_bank:            .res 1  ; bank containing the current block's bitstream
	slopes_bank:          .res 1  ; bank containing the current block's slopes
	ptr_bitstream:        .res 2  ; pointer to position in bitstream
	ptr_slopes:           .res 2  ; pointer to slope list for this block
	superblock_length:    .res 1  ; length of current superblock in blocks
	last_sample:          .res 1  ; value of the last sample, used by the decode routine
	
	; ---------------------
	; Sample playback IRQ
	; ---------------------
	tmp_irq_a:            .res 1  ; temporary location for IRQ routine to save the "a" register
	irq_latch_value:      .res 1  ; value written to the IRQ latch, determines the sample rate
	
	; ---------------------
	; NMI
	; ---------------------
	nmi_semaph:        .res 1  ; semaphore for NMI to handle reentrancy
	

.globalzp idx_superblock, idx_block, idx_pcm_decode, idx_pcm_playback
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample
.globalzp bits_bank, slopes_bank
.globalzp tmp_irq_a, irq_latch_value
.globalzp nmi_semaph

; ---------------------------------------------
; Space reservations for non-allocatable areas
; ---------------------------------------------

.segment "SHORTRAM"
	; nothing here yet!

.segment "OAM"
.org $0200
	buf_oam: .res 256

.segment "SAMPLE_BUF"
.org $0300
.global buf_pcm
	buf_pcm: .res 256
