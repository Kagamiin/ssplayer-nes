
.scope piece0
	.include "thelittlethings-ss2_0_params.inc"
	.segment "BANK_00"
	bits:
		.incbin "thelittlethings-ss2_0_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_0_slopes.bin"
.endscope

.scope piece1
	.include "thelittlethings-ss2_1_params.inc"
	.segment "BANK_01"
	bits:
		.incbin "thelittlethings-ss2_1_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_1_slopes.bin"
.endscope

.scope piece2
	.include "thelittlethings-ss2_2_params.inc"
	.segment "BANK_02"
	bits:
		.incbin "thelittlethings-ss2_2_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_2_slopes.bin"
.endscope

.scope piece3
	.include "thelittlethings-ss2_3_params.inc"
	.segment "BANK_03"
	bits:
		.incbin "thelittlethings-ss2_3_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_3_slopes.bin"
.endscope

.scope piece4
	.include "thelittlethings-ss2_4_params.inc"
	.segment "BANK_04"
	bits:
		.incbin "thelittlethings-ss2_4_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_4_slopes.bin"
.endscope

.scope piece5
	.include "thelittlethings-ss2_5_params.inc"
	.segment "BANK_05"
	bits:
		.incbin "thelittlethings-ss2_5_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_5_slopes.bin"
.endscope

.scope piece6
	.include "thelittlethings-ss2_6_params.inc"
	.segment "BANK_06"
	bits:
		.incbin "thelittlethings-ss2_6_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_6_slopes.bin"
.endscope

.scope piece7
	.include "thelittlethings-ss2_7_params.inc"
	.segment "BANK_07"
	bits:
		.incbin "thelittlethings-ss2_7_bits.bin"

	.segment "BANK_07"
	slopes:
		.incbin "thelittlethings-ss2_7_slopes.bin"
.endscope

