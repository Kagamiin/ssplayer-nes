.ifndef __CHECKED_BRANCHES_INC__
__CHECKED_BRANCHES_INC__ = 1

.macro _chk_b target
	.assert >* = >target, error, "branch crosses a page boundary"
.endmacro

.macro _chk_b_x target
	.assert >* <> >target, error, "branch does not cross a page boundary"
.endmacro

.macro c_bcc target
	bcc target
	_chk_b target
.endmacro

.macro c_bcs target
	bcs target
	_chk_b target
.endmacro

.macro c_beq target
	beq target
	_chk_b target
.endmacro

.macro c_bne target
	bne target
	_chk_b target
.endmacro

.macro c_bmi target
	bmi target
	_chk_b target
.endmacro

.macro c_bpl target
	bpl target
	_chk_b target
.endmacro

.macro c_bvc target
	bvc target
	_chk_b target
.endmacro

.macro c_bvs target
	bvs target
	_chk_b target
.endmacro



.macro x_bcc target
	bcc target
	_chk_b_x target
.endmacro

.macro x_bcs target
	bcs target
	_chk_b_x target
.endmacro

.macro x_beq target
	beq target
	_chk_b_x target
.endmacro

.macro x_bne target
	bne target
	_chk_b_x target
.endmacro

.macro x_bmi target
	bmi target
	_chk_b_x target
.endmacro

.macro x_bpl target
	bpl target
	_chk_b_x target
.endmacro

.macro x_bvc target
	bvc target
	_chk_b_x target
.endmacro

.macro x_bvs target
	bvs target
	_chk_b_x target
.endmacro

.endif
