; Place the category ("phy", "spc" or "sta") of move a at hl.
; Expands to a local routine in each bank that needs it (home is full).
MACRO place_move_category_name
\1:
	call GetMoveCategory
	ld de, .Physical
	cp MOVE_CAT_SPECIAL
	jr c, .got_name
	ld de, .Special
	jr z, .got_name
	ld de, .Status
.got_name
	jp PlaceString

.Physical: db "phy@"
.Special:  db "spc@"
.Status:   db "sta@"
ENDM
