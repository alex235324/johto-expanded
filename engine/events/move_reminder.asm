; Move Reminder: the Trade Center receptionist on every Pokémon Center 2F
; (maps/Pokecenter2F.asm) re-teaches level-up moves a Pokémon has forgotten
; or skipped: any move in its learnset at or below its level that it doesn't know.
; Free of charge.

DEF MOVE_REMINDER_MAX EQU 60 ; most moves listed at once

; Scratch space: the enemy party structs, which are only used in battles and links.
DEF wMoveReminderList  EQUS "(wOTPartyMons)"        ; count, 1..count, -1 (scrolling menu items)
DEF wMoveReminderMoves EQUS "(wOTPartyMons + 64)"   ; count 16-bit move indexes (little endian)
DEF wMoveReminderKnown EQUS "(wOTPartyMons + 64 + 2 * MOVE_REMINDER_MAX)" ; the mon's 4 moves, 16-bit
DEF wMoveReminderLevel EQUS "(wOTPartyMons + 64 + 2 * MOVE_REMINDER_MAX + 2 * NUM_MOVES)"
assert 64 + 2 * MOVE_REMINDER_MAX + 2 * NUM_MOVES + 1 <= PARTYMON_STRUCT_LENGTH * PARTY_LENGTH
assert MOVE_REMINDER_MAX + 2 <= 64

; MoveReminder return values (wScriptVar)
	const_def
	const MOVEREMINDER_LEARNED
	const MOVEREMINDER_CANCELLED
	const MOVEREMINDER_EGG
	const MOVEREMINDER_NO_MOVES
	const MOVEREMINDER_DIDNT_LEARN

MoveReminderScript::
	faceplayer
	opentext
if QOL_CENTER_MOVE_DELETER
; Offer both services: remember a move (Move Reminder) or forget one (Move Deleter).
	writetext MoveReminderMenuIntroText
	loadmenu .MenuHeader
	verticalmenu
	closewindow
	ifequal 1, .Remember
	ifequal 2, .Forget
	writetext MoveReminderComeBackText
	waitbutton
	closetext
	end

.Forget:
	special MoveReminderForgetMove
	waitbutton
	closetext
	end

.MenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 2, 4, SCREEN_WIDTH - 1, TEXTBOX_Y - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR ; flags
	db 3 ; items
	db "Remember a move@"
	db "Forget a move@"
	db "Cancel@"

.Remember:
	writetext MoveReminderWhichMonText
	promptbutton
else
	writetext MoveReminderIntroText
	promptbutton
endc
	special MoveReminder
	ifequal MOVEREMINDER_LEARNED, .Learned
	ifequal MOVEREMINDER_EGG, .Egg
	ifequal MOVEREMINDER_NO_MOVES, .NoMoves
	writetext MoveReminderComeBackText
	waitbutton
	closetext
	end

.Learned:
	writetext MoveReminderLearnedText
	waitbutton
	closetext
	end

.Egg:
	writetext MoveReminderEggText
	waitbutton
	closetext
	end

.NoMoves:
	writetext MoveReminderNoMovesText
	waitbutton
	closetext
	end

MoveReminderIntroText:
	text "Hi! I'm the Move"
	line "Reminder."

	para "I can help a"
	line "#mon remember a"
	cont "move it forgot."

	para "It's free! Which"
	line "#mon should I"
	cont "help?"
	done

if QOL_CENTER_MOVE_DELETER
MoveReminderMenuIntroText:
	text "Hi! I can help a"
	line "#mon remember a"
	cont "move, or forget"
	cont "one. It's free!"
	done

MoveReminderWhichMonText:
	text "Which #mon"
	line "should I help?"
	done

MoveReminderForgetMove:
; The Move Deleter's flow from Blackthorn, without his introduction.
	farcall MoveDeletion.ask_which_mon
	ret

endc
MoveReminderComeBackText:
	text "Come back any"
	line "time you like!"
	done

MoveReminderLearnedText:
	text "All done! Come"
	line "back any time!"
	done

MoveReminderEggText:
	text "That Egg hasn't"
	line "learned anything"
	cont "yet!"
	done

MoveReminderNoMovesText:
	text "Hmm… There's no"
	line "move it can"
	cont "remember right"
	cont "now."
	done

MoveReminder:
	farcall SelectMonFromParty
	ld a, MOVEREMINDER_CANCELLED
	jr c, .done
	ld a, [wCurPartySpecies]
	cp EGG
	ld a, MOVEREMINDER_EGG
	jr z, .done
	call MoveReminder_BuildList
	ld a, [wMoveReminderList]
	and a
	ld a, MOVEREMINDER_NO_MOVES
	jr z, .done

	call MoveReminder_ChooseMove
	ld a, MOVEREMINDER_CANCELLED
	jr z, .done

; teach it
	ld a, [wMenuSelection]
	call MoveReminder_GetMoveIndex
	call GetMoveIDFromIndex
	ld [wPutativeTMHMMove], a
	ld [wNamedObjectIndex], a
	call GetMoveName
	call CopyName1
	ld a, [wCurPartyMon]
	ld hl, wPartyMonNicknames
	call GetNickname
	; hide the overworld sprites, or they'd cover the "forget a move" menu
	call DisableSpriteUpdates
	call ClearSprites
	predef LearnMove
	; the "which move should be forgotten?" screen changes the palettes
	ld a, b
	call ReturnToMapWithSpeechTextbox ; preserves a
	and a
	ld a, MOVEREMINDER_DIDNT_LEARN
	jr z, .done
	ld a, MOVEREMINDER_LEARNED
.done
	ld [wScriptVar], a
	ret

; hl = 16-bit index of list entry a (1-based)
MoveReminder_GetMoveIndex:
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld de, wMoveReminderMoves
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

MoveReminder_BuildList:
; the moves it knows, as 16-bit indexes
	ld a, MON_MOVES
	call GetPartyParamLocation
	ld de, wMoveReminderKnown
	ld b, NUM_MOVES
.known_loop
	ld a, [hli]
	push hl
	push bc
	push de
	ld hl, 0
	and a
	call nz, GetMoveIndexFromID
	pop de
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a
	inc de
	pop bc
	pop hl
	dec b
	jr nz, .known_loop

	ld a, MON_LEVEL
	call GetPartyParamLocation
	ld a, [hl]
	ld [wMoveReminderLevel], a
	xor a
	ld [wMoveReminderList], a

; find its learnset and skip the evolutions
	ld a, [wCurPartySpecies]
	call GetPokemonIndexFromID
	ld b, h
	ld c, l
	ld hl, EvosAttacksPointers
	ld a, BANK(EvosAttacksPointers)
	call LoadDoubleIndirectPointer
	ldh [hTemp], a
.skip_evos
	call .NextByte
	and a
	jr z, .moves
	cp EVOLVE_STAT
	jr nz, .no_extra_byte
	inc hl
.no_extra_byte
	inc hl
	inc hl
	inc hl
	jr .skip_evos

.moves
	call .NextByte ; level (0 = end)
	and a
	jr z, .make_menu_list
	ld b, a
	call .NextByte
	ld e, a
	call .NextByte
	ld d, a ; de = move index
	ld a, [wMoveReminderLevel]
	cp b
	jr c, .moves ; learned later

	push hl
	ld hl, wMoveReminderKnown
	ld c, NUM_MOVES
	call .InList
	jr c, .skip_move
	ld hl, wMoveReminderMoves
	ld a, [wMoveReminderList]
	ld c, a
	call .InList ; listed twice in the learnset
	jr c, .skip_move
	ld a, [wMoveReminderList]
	cp MOVE_REMINDER_MAX
	jr nc, .skip_move
	inc a
	ld [wMoveReminderList], a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, wMoveReminderMoves - 2
	add hl, bc
	ld [hl], e
	inc hl
	ld [hl], d
.skip_move
	pop hl
	jr .moves

.make_menu_list
	ld hl, wMoveReminderList
	ld a, [hli]
	ld c, a
	ld b, 1
	and a
	jr z, .terminate
.fill
	ld a, b
	ld [hli], a
	inc b
	dec c
	jr nz, .fill
.terminate
	ld [hl], -1
	ret

.NextByte:
	ldh a, [hTemp]
	call GetFarByte
	inc hl
	ret

.InList:
; carry if de is one of the c 16-bit values at hl
	ld a, c
	and a
	ret z
.in_list_loop
	ld a, [hli]
	cp e
	jr nz, .next
	ld a, [hl]
	cp d
	jr z, .found
.next
	inc hl
	dec c
	jr nz, .in_list_loop
	and a
	ret

.found
	scf
	ret

; returns z if cancelled, else wMenuSelection = list entry
MoveReminder_ChooseMove:
	xor a
	ld [wMenuScrollPosition], a
	ld a, 1
	ld [wMenuSelection], a
	ld hl, .BoxHeader
	call LoadMenuHeader
	ld hl, .WhichMoveText
	call PrintText
	call DelayFrame
	call UpdateSprites
	ld hl, .MenuHeader
	call CopyMenuHeader
	ld a, [wMenuSelection]
	ld [wMenuCursorPosition], a
	xor a
	ld [wWhichIndexSet], a
	ldh [hBGMapMode], a
	call InitScrollingMenu
	call UpdateSprites
	call ScrollingMenu
	ld a, [wMenuJoypad]
	push af
	call CloseWindow
	pop af
	cp PAD_B
	jr z, .cancel
	ld a, [wMenuSelection]
	cp -1 ; CANCEL
	jr z, .cancel
	and a
	ret

.cancel
	xor a
	ret

.WhichMoveText:
	text "Which move should"
	line "it remember?"
	done

.BoxHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 19, TEXTBOX_Y - 1

.MenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 1, 1, 18, 9
	dw .MenuData
	db 1 ; default option
	db 0

.MenuData:
	db SCROLLINGMENU_DISPLAY_ARROWS ; flags
	db 4, 0 ; rows, columns
	db SCROLLINGMENU_ITEMS_NORMAL ; item format
	db BANK(wOTPartyMons) ; the list is in WRAM
	dw wMoveReminderList
	dba .PrintMove
	dba .PrintMove ; unused (no columns)

.PrintMove:
	ld a, [wMenuSelection]
	push de
	call MoveReminder_GetMoveIndex
	call GetMoveIDFromIndex
	ld [wNamedObjectIndex], a
	call GetMoveName
	pop hl
	jp PlaceString
