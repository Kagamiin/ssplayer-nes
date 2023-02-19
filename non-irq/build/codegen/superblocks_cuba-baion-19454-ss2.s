.include "blocks_cuba-baion-19454-ss2.inc"

.segment "HDRS"

;.export sblk_header_s
;.struct sblk_header_s
;	bits_bank       .byte
;	slopes_bank     .byte
;	bits            .addr
;	slopes          .addr
;	initial_sample  .byte
;	length          .byte
;.endstruct

.export sblk_table
sblk_table:
	.byte piece00::bits_bank       ; bits_bank
	.byte piece00::slopes_bank     ; slopes_bank
	.addr piece00::bits            ; bits
	.addr piece00::slopes          ; slopes
	.byte piece00::initial_sample  ; initial_sample
	.byte piece00::length          ; length

	.byte piece01::bits_bank       ; bits_bank
	.byte piece01::slopes_bank     ; slopes_bank
	.addr piece01::bits            ; bits
	.addr piece01::slopes          ; slopes
	.byte piece01::initial_sample  ; initial_sample
	.byte piece01::length          ; length

	.byte piece02::bits_bank       ; bits_bank
	.byte piece02::slopes_bank     ; slopes_bank
	.addr piece02::bits            ; bits
	.addr piece02::slopes          ; slopes
	.byte piece02::initial_sample  ; initial_sample
	.byte piece02::length          ; length

	.byte piece03::bits_bank       ; bits_bank
	.byte piece03::slopes_bank     ; slopes_bank
	.addr piece03::bits            ; bits
	.addr piece03::slopes          ; slopes
	.byte piece03::initial_sample  ; initial_sample
	.byte piece03::length          ; length

	.byte piece04::bits_bank       ; bits_bank
	.byte piece04::slopes_bank     ; slopes_bank
	.addr piece04::bits            ; bits
	.addr piece04::slopes          ; slopes
	.byte piece04::initial_sample  ; initial_sample
	.byte piece04::length          ; length

	.byte piece05::bits_bank       ; bits_bank
	.byte piece05::slopes_bank     ; slopes_bank
	.addr piece05::bits            ; bits
	.addr piece05::slopes          ; slopes
	.byte piece05::initial_sample  ; initial_sample
	.byte piece05::length          ; length

	.byte piece06::bits_bank       ; bits_bank
	.byte piece06::slopes_bank     ; slopes_bank
	.addr piece06::bits            ; bits
	.addr piece06::slopes          ; slopes
	.byte piece06::initial_sample  ; initial_sample
	.byte piece06::length          ; length

	.byte piece07::bits_bank       ; bits_bank
	.byte piece07::slopes_bank     ; slopes_bank
	.addr piece07::bits            ; bits
	.addr piece07::slopes          ; slopes
	.byte piece07::initial_sample  ; initial_sample
	.byte piece07::length          ; length

	.byte piece08::bits_bank       ; bits_bank
	.byte piece08::slopes_bank     ; slopes_bank
	.addr piece08::bits            ; bits
	.addr piece08::slopes          ; slopes
	.byte piece08::initial_sample  ; initial_sample
	.byte piece08::length          ; length

	.byte piece09::bits_bank       ; bits_bank
	.byte piece09::slopes_bank     ; slopes_bank
	.addr piece09::bits            ; bits
	.addr piece09::slopes          ; slopes
	.byte piece09::initial_sample  ; initial_sample
	.byte piece09::length          ; length

	.byte piece0a::bits_bank       ; bits_bank
	.byte piece0a::slopes_bank     ; slopes_bank
	.addr piece0a::bits            ; bits
	.addr piece0a::slopes          ; slopes
	.byte piece0a::initial_sample  ; initial_sample
	.byte piece0a::length          ; length

.export num_sblk_headers
num_sblk_headers:
	.byte 11
