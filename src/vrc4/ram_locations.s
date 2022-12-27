
.segment "ZEROPAGE"
	.org $00   ; assert we're at the start of zeropage
	.res 16    ; temporaries $0..$f

	idx_superblock:       .res 1  ; index of currently-playing superblock
	idx_block:            .res 1  ; index of block in superblock
	idx_pcm_decode:       .res 1  ; index of next sample to be overwritten by the decoder
.if 0
	idx_pcm_playback:     .res 1  ; index of next sample to be played
.endif

	bits_bank:            .res 1  ; bank containing the current block's bitstream
	slopes_bank:          .res 1  ; bank containing the current block's slopes
	ptr_bitstream:        .res 2  ; pointer to position in bitstream
	ptr_slopes:           .res 2  ; pointer to slope list for this block
	superblock_length:    .res 1  ; length of current superblock in blocks
	last_sample:          .res 1  ; value of the last sample, used by the decode routine
	tmp_irq_a:            .res 1  ; temporary location for IRQ routine to save the a register

.globalzp idx_superblock, idx_block, idx_pcm_decode, idx_pcm_playback
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample
.globalzp bits_bank, slopes_bank
.globalzp tmp_irq_a

.segment "BSS"
.org $0200
	buf_pcm: .res 256

.global buf_pcm
