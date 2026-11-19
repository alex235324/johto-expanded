; Permanent Cut: each tree in CutTreeLocations has an event flag.
; CUT_TREE_ENTRY_SIZE: map_id (2), flag (2), wOverworldMapBlocks offset (2), replacement block (1)
DEF CUT_TREE_ENTRY_SIZE EQU 7

RecordCutTree::
; Called after a tree is cut: set the flag of the tree at wCutWhirlpoolOverworldBlockAddr.
	ld hl, wCutWhirlpoolOverworldBlockAddr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, l
	sub LOW(wOverworldMapBlocks)
	ld e, a
	ld a, h
	sbc HIGH(wOverworldMapBlocks)
	ld d, a
	ld hl, CutTreeLocations
.loop
	ld a, [hl]
	cp -1
	ret z
	push hl
	call .IsThisMap
	jr nz, .next
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hli]
	cp e
	jr nz, .next
	ld a, [hl]
	cp d
	jr nz, .next
	pop hl
	inc hl
	inc hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld b, SET_FLAG
	jp EventFlagAction

.next
	pop hl
	ld bc, CUT_TREE_ENTRY_SIZE
	add hl, bc
	jr .loop

.IsThisMap:
; z if the entry at hl is the current map (hl unchanged)
	ld a, [wMapGroup]
	cp [hl]
	ret nz
	inc hl
	ld a, [wMapNumber]
	cp [hl]
	dec hl
	ret

ApplyCutTrees::
; Called after a map's blocks are loaded: re-cut every tree on it whose flag is set.
	ld hl, CutTreeLocations
.loop
	ld a, [hl]
	cp -1
	ret z
	push hl
	call RecordCutTree.IsThisMap
	jr nz, .next
	inc hl
	inc hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	push hl
	ld b, CHECK_FLAG
	call EventFlagAction
	pop hl
	ld a, c
	and a
	jr z, .next
	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl
	ld a, [hl] ; replacement block
	ld hl, wOverworldMapBlocks
	add hl, de
	ld [hl], a
.next
	pop hl
	ld bc, CUT_TREE_ENTRY_SIZE
	add hl, bc
	jr .loop

INCLUDE "data/events/cut_trees.asm"
