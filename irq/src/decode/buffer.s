.include "smc.inc"
.include "nes_mmio.inc"

.import decode_async

.globalzp idx_pcm_decode, irq_latch_value

.ifdef USE_FIXED_BANK
	.out "Selected fixed bank."
	.segment "DECODE_FIXBANK"
.else
	.out "Selected decode bank."
	.segment "DECODE"
.endif

; Fills the sample buffer with as many samples as needed to not underflow until next frame
.export fill_buffer
.proc fill_buffer

.importzp SAMPLES_PER_DECODE_CALL

.global ppumask_shadow

SMC_Import idx_smc_pcm_playback

	start_playback_pos = $8
	playback_offset = $9
	tmp_playback_pos = $a

	lda ppumask_shadow
	ora #$21
	sta PPUMASK
	
	SMC_LoadLowByte idx_smc_pcm_playback, a
	sta start_playback_pos
	
@buffer_check:
	SMC_LoadLowByte idx_smc_pcm_playback, a
	sta tmp_playback_pos
	sec
	sbc idx_pcm_decode
	cmp #SAMPLES_PER_DECODE_CALL
	bcs @fill_buffer          ; if there's at least 64 samples of slack, go fill the buffer
	
@after_fill_buffer:
	lsr a
	tax
	ldy irq_latch_value
	cpy #(256 - 118)
	bcc @period_gt_118

	@period_le_118:                   ; if period is less than (faster) or equal to 118
		txa
		clc
		adc samplecnt_offs_tbl, y ; offset buffer slack / 2
		;                         ; by (num samples/frame - 256) / 2
		
		tax                       ; x = frame-related buffer slack
		
		lda tmp_playback_pos
		sec
		sbc start_playback_pos
		lsr a
		jmp @after
		
	@period_gt_118:                   ; if period is greater (slower) than 118
		lda tmp_playback_pos
		sec
		sbc start_playback_pos
		lsr a
		ldy irq_latch_value
		adc samplecnt_offs_tbl, y ; offset playback_offset / 2
		;                         ; by (256 - num samples/frame) / 2
@after:
	sta playback_offset
	txa
	sec
	sbc playback_offset       ; are there enough samples in the buffer to last
	;                         ; until the next iteration?
	bcs @buffer_check

	lda ppumask_shadow
	sta PPUMASK
	rts
	
@fill_buffer:
	lda ppumask_shadow
	ora #$81
	sta PPUMASK
	jsr decode_async       ; go decode a block
	
	lda ppumask_shadow
	ora #$21
	sta PPUMASK
	lda tmp_playback_pos
	sec
	sbc idx_pcm_decode
	jmp @after_fill_buffer     ; check again

; Table of offsets for frame-related buffer size prediction
samplecnt_offs_tbl:
	.byte  68    ; period 256-256
	.byte  68    ; period 256-255
	.byte  68    ; period 256-254
	.byte  68    ; period 256-253
	.byte  67    ; period 256-252
	.byte  67    ; period 256-251
	.byte  67    ; period 256-250
	.byte  67    ; period 256-249
	.byte  66    ; period 256-248
	.byte  66    ; period 256-247
	.byte  66    ; period 256-246
	.byte  66    ; period 256-245
	.byte  65    ; period 256-244
	.byte  65    ; period 256-243
	.byte  65    ; period 256-242
	.byte  65    ; period 256-241
	.byte  64    ; period 256-240
	.byte  64    ; period 256-239
	.byte  64    ; period 256-238
	.byte  64    ; period 256-237
	.byte  63    ; period 256-236
	.byte  63    ; period 256-235
	.byte  63    ; period 256-234
	.byte  62    ; period 256-233
	.byte  62    ; period 256-232
	.byte  62    ; period 256-231
	.byte  62    ; period 256-230
	.byte  61    ; period 256-229
	.byte  61    ; period 256-228
	.byte  61    ; period 256-227
	.byte  61    ; period 256-226
	.byte  60    ; period 256-225
	.byte  60    ; period 256-224
	.byte  60    ; period 256-223
	.byte  59    ; period 256-222
	.byte  59    ; period 256-221
	.byte  59    ; period 256-220
	.byte  58    ; period 256-219
	.byte  58    ; period 256-218
	.byte  58    ; period 256-217
	.byte  57    ; period 256-216
	.byte  57    ; period 256-215
	.byte  57    ; period 256-214
	.byte  56    ; period 256-213
	.byte  56    ; period 256-212
	.byte  56    ; period 256-211
	.byte  55    ; period 256-210
	.byte  55    ; period 256-209
	.byte  55    ; period 256-208
	.byte  54    ; period 256-207
	.byte  54    ; period 256-206
	.byte  54    ; period 256-205
	.byte  53    ; period 256-204
	.byte  53    ; period 256-203
	.byte  53    ; period 256-202
	.byte  52    ; period 256-201
	.byte  52    ; period 256-200
	.byte  52    ; period 256-199
	.byte  51    ; period 256-198
	.byte  51    ; period 256-197
	.byte  50    ; period 256-196
	.byte  50    ; period 256-195
	.byte  50    ; period 256-194
	.byte  49    ; period 256-193
	.byte  49    ; period 256-192
	.byte  48    ; period 256-191
	.byte  48    ; period 256-190
	.byte  48    ; period 256-189
	.byte  47    ; period 256-188
	.byte  47    ; period 256-187
	.byte  46    ; period 256-186
	.byte  46    ; period 256-185
	.byte  45    ; period 256-184
	.byte  45    ; period 256-183
	.byte  45    ; period 256-182
	.byte  44    ; period 256-181
	.byte  44    ; period 256-180
	.byte  43    ; period 256-179
	.byte  43    ; period 256-178
	.byte  42    ; period 256-177
	.byte  42    ; period 256-176
	.byte  41    ; period 256-175
	.byte  41    ; period 256-174
	.byte  40    ; period 256-173
	.byte  40    ; period 256-172
	.byte  39    ; period 256-171
	.byte  39    ; period 256-170
	.byte  38    ; period 256-169
	.byte  38    ; period 256-168
	.byte  37    ; period 256-167
	.byte  37    ; period 256-166
	.byte  36    ; period 256-165
	.byte  36    ; period 256-164
	.byte  35    ; period 256-163
	.byte  34    ; period 256-162
	.byte  34    ; period 256-161
	.byte  33    ; period 256-160
	.byte  33    ; period 256-159
	.byte  32    ; period 256-158
	.byte  32    ; period 256-157
	.byte  31    ; period 256-156
	.byte  30    ; period 256-155
	.byte  30    ; period 256-154
	.byte  29    ; period 256-153
	.byte  28    ; period 256-152
	.byte  28    ; period 256-151
	.byte  27    ; period 256-150
	.byte  26    ; period 256-149
	.byte  26    ; period 256-148
	.byte  25    ; period 256-147
	.byte  24    ; period 256-146
	.byte  24    ; period 256-145
	.byte  23    ; period 256-144
	.byte  22    ; period 256-143
	.byte  21    ; period 256-142
	.byte  21    ; period 256-141
	.byte  20    ; period 256-140
	.byte  19    ; period 256-139
	.byte  18    ; period 256-138
	.byte  18    ; period 256-137
	.byte  17    ; period 256-136
	.byte  16    ; period 256-135
	.byte  15    ; period 256-134
	.byte  14    ; period 256-133
	.byte  14    ; period 256-132
	.byte  13    ; period 256-131
	.byte  12    ; period 256-130
	.byte  11    ; period 256-129
	.byte  10    ; period 256-128
	.byte   9    ; period 256-127
	.byte   8    ; period 256-126
	.byte   7    ; period 256-125
	.byte   6    ; period 256-124
	.byte   5    ; period 256-123
	.byte   4    ; period 256-122
	.byte   3    ; period 256-121
	.byte   2    ; period 256-120
	.byte   1    ; period 256-119
	;            ; (256 - num samples/frame) / 2
	
	;            ; (num samples/frame - 256) / 2
	.byte   0    ; period 256-118
	.byte   1    ; period 256-117
	.byte   2    ; period 256-116
	.byte   3    ; period 256-115
	.byte   4    ; period 256-114 -- almost 1 sample per scanline
	.byte   5    ; period 256-113
	.byte   7    ; period 256-112
	.byte   8    ; period 256-111
	.byte   9    ; period 256-110
	.byte  10    ; period 256-109
	.byte  12    ; period 256-108
	.byte  13    ; period 256-107
	.byte  14    ; period 256-106
	.byte  16    ; period 256-105
	.byte  17    ; period 256-104
	.byte  18    ; period 256-103
	.byte  20    ; period 256-102
	.byte  21    ; period 256-101
	.byte  23    ; period 256-100
	.byte  24    ; period 256-99
	.byte  26    ; period 256-98
	.byte  27    ; period 256-97
	.byte  29    ; period 256-96
	.byte  30    ; period 256-95
	.byte  32    ; period 256-94
	.byte  34    ; period 256-93
	.byte  36    ; period 256-92
	.byte  37    ; period 256-91
	.byte  39    ; period 256-90
	.byte  41    ; period 256-89
	.byte  43    ; period 256-88
	.byte  45    ; period 256-87
	.byte  47    ; period 256-86
	.byte  49    ; period 256-85
	.byte  51    ; period 256-84
	.byte  53    ; period 256-83
	.byte  55    ; period 256-82
	.byte  58    ; period 256-81
	.byte  60    ; period 256-80
	.byte  62    ; period 256-79
	.byte  65    ; period 256-78
	.byte  67    ; period 256-77
	.byte  70    ; period 256-76
	.byte  72    ; period 256-75
	.byte  75    ; period 256-74
	.byte  78    ; period 256-73
	.byte  81    ; period 256-72
	.byte  84    ; period 256-71
	.byte  87    ; period 256-70
	.byte  90    ; period 256-69
	.byte  93    ; period 256-68
	.byte  96    ; period 256-67
	.byte  99    ; period 256-66
	.byte 103    ; period 256-65
	.byte 107    ; period 256-64
	;            ; this is way more than enough values

	
.endproc
