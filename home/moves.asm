GetMoveAttribute::
; Return attribute a of move l in a; clobbers hl.
; Replaces the old GetMoveAttr (renamed to avoid confusion).
	sub 1
	push bc
	ld c, a
	ld a, l
	jr c, .done
	call GetMoveAddress
	ld b, 0
	add hl, bc
	call GetFarByte
.done
	pop bc
	ret

GetMoveAddress::
; Get the far address for move a's attributes in a:hl.
; This structure will not contain the animation byte! All MOVE_* constants must be reduced by 1 when indexing.
	push bc
	call GetMoveIndexFromID
	ld b, h
	ld c, l
	ld hl, Moves
	ld a, BANK(Moves)
	call LoadIndirectPointer
	pop bc
	ret

GetMoveData::
; Copy move struct a to de.
	ld [de], a
	inc de
	call GetMoveAddress
	ld bc, MOVE_LENGTH - 1
	jp FarCopyBytes

GetMoveCategory::
; a = move ID -> a = MOVE_CAT_PHYSICAL, MOVE_CAT_SPECIAL or MOVE_CAT_STATUS.
; Keeps bc, de and hl. Compare with MOVE_CAT_SPECIAL: carry means physical,
; the same as the old "cp SPECIAL" type check.
	push hl
	push de
	push bc
	call GetMoveIndexFromID
	ld de, MoveCategories - 1
	add hl, de
	ld a, BANK(MoveCategories)
	call GetFarByte
	pop bc
	pop de
	pop hl
	ret
