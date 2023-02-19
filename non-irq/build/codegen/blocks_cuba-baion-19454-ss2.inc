
.scope piece00
	.include "cuba-baion-19454-ss2_0_params.inc"
	bits_bank := $00
	slopes_bank := $05
	.segment "BANK_00"
	bits:
		.incbin "cuba-baion-19454-ss2_0_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_0_slopes.bin"
.endscope

.scope piece01
	.include "cuba-baion-19454-ss2_1_params.inc"
	bits_bank := $00
	slopes_bank := $05
	.segment "BANK_00"
	bits:
		.incbin "cuba-baion-19454-ss2_1_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_1_slopes.bin"
.endscope

.scope piece02
	.include "cuba-baion-19454-ss2_2_params.inc"
	bits_bank := $01
	slopes_bank := $05
	.segment "BANK_01"
	bits:
		.incbin "cuba-baion-19454-ss2_2_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_2_slopes.bin"
.endscope

.scope piece03
	.include "cuba-baion-19454-ss2_3_params.inc"
	bits_bank := $01
	slopes_bank := $05
	.segment "BANK_01"
	bits:
		.incbin "cuba-baion-19454-ss2_3_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_3_slopes.bin"
.endscope

.scope piece04
	.include "cuba-baion-19454-ss2_4_params.inc"
	bits_bank := $02
	slopes_bank := $05
	.segment "BANK_02"
	bits:
		.incbin "cuba-baion-19454-ss2_4_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_4_slopes.bin"
.endscope

.scope piece05
	.include "cuba-baion-19454-ss2_5_params.inc"
	bits_bank := $02
	slopes_bank := $05
	.segment "BANK_02"
	bits:
		.incbin "cuba-baion-19454-ss2_5_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_5_slopes.bin"
.endscope

.scope piece06
	.include "cuba-baion-19454-ss2_6_params.inc"
	bits_bank := $03
	slopes_bank := $05
	.segment "BANK_03"
	bits:
		.incbin "cuba-baion-19454-ss2_6_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_6_slopes.bin"
.endscope

.scope piece07
	.include "cuba-baion-19454-ss2_7_params.inc"
	bits_bank := $03
	slopes_bank := $05
	.segment "BANK_03"
	bits:
		.incbin "cuba-baion-19454-ss2_7_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_7_slopes.bin"
.endscope

.scope piece08
	.include "cuba-baion-19454-ss2_8_params.inc"
	bits_bank := $04
	slopes_bank := $05
	.segment "BANK_04"
	bits:
		.incbin "cuba-baion-19454-ss2_8_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_8_slopes.bin"
.endscope

.scope piece09
	.include "cuba-baion-19454-ss2_9_params.inc"
	bits_bank := $04
	slopes_bank := $05
	.segment "BANK_04"
	bits:
		.incbin "cuba-baion-19454-ss2_9_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_9_slopes.bin"
.endscope

.scope piece0a
	.include "cuba-baion-19454-ss2_10_params.inc"
	bits_bank := $05
	slopes_bank := $05
	.segment "BANK_05"
	bits:
		.incbin "cuba-baion-19454-ss2_10_bits.bin"

	.segment "BANK_05"
	slopes:
		.incbin "cuba-baion-19454-ss2_10_slopes.bin"
.endscope
