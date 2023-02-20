
.segment "ZEROPAGE"
	tmp_addr:                .res 2  ; temporary jump address
	tmp_ret_addr:            .res 2  ; temporary return address
	tmp_src_addr:            .res 2  ;
	tmp_jmptbl_start_offset: .res 1  ;
	tmp_ret_template_offset: .res 1  ;
	tmp_mask:                .res 1  ;

	tmp_shortbuf:            .res 1  ;

	idx_superblock:       .res 1  ; index of currently-playing superblock
	idx_block:            .res 1  ; index of block in superblock
	idx_pcm_decode:       .res 1  ; index of next sample to be overwritten by the decoder
	idx_pcm_playback:     .res 1  ; index of next sample to be played

	ptr_bitstream:        .res 2  ; pointer to position in bitstream
	ptr_slopes:           .res 2  ; pointer to slope list for this block
	superblock_length:    .res 1  ; length of current superblock in blocks
	last_sample:          .res 1  ; value of the last sample, used by the decode routine
	block_slope:          .res 1  ; copy of block's current slope value (temporary)

.globalzp tmp_addr, tmp_ret_addr, tmp_shortbuf
.globalzp tmp_jmptbl_start_offset, tmp_ret_template_offset, tmp_src_addr, tmp_mask
.globalzp idx_superblock, idx_block, idx_pcm_decode, idx_pcm_playback
.globalzp ptr_bitstream, ptr_slopes, superblock_length, last_sample, block_slope

.segment "BSS"
	buf_pcm: .res 256

.global buf_pcm

.align 64                           ; HACK: forcing jump tables to be in the same page
.segment "DYNCODE"
	decode_byte_jump_tbl1_low: .res 16
	decode_byte_jump_tbl1_high: .res 16
	decode_byte_jump_tbl2_low: .res 16
	decode_byte_jump_tbl2_high: .res 16

.global decode_byte_jump_tbl1_low, decode_byte_jump_tbl1_high
.global decode_byte_jump_tbl2_low, decode_byte_jump_tbl2_high

.export decode_code_array
	decode_code_array: .res (31 * 32)
