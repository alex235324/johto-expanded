DEF BATTLEMENU_RUN EQU 4 ; FIGHT 1, PKMN 2, PACK 3, RUN 4 (2x2, row-major)

LoadBattleMenu:
; In a wild battle you can run from, B moves the cursor to RUN and B again on
; RUN picks RUN. Anywhere else (trainers, links, trapped) B does nothing.
	ld hl, BattleMenuHeader
	call LoadMenuHeader
.loop
	ld a, [wBattleMenuCursorPosition]
	ld [wMenuCursorPosition], a
	call InterpretBattleMenu
	call GetMenuJoypad
	bit B_PAD_B, a
	jr nz, .b_button
	ld a, [wMenuCursorPosition]
	ld [wBattleMenuCursorPosition], a
	call ExitMenu
	ret

.b_button
	; the menu doesn't store the cursor on B, so work it out: (row - 1) * 2 + column
	ld a, [wMenuCursorY]
	dec a
	add a
	ld b, a
	ld a, [wMenuCursorX]
	add b
	ld [wBattleMenuCursorPosition], a ; stay where the cursor is if B is ignored
	call .CanRunWithB
	jr nc, .loop
	ld a, [wBattleMenuCursorPosition]
	cp BATTLEMENU_RUN
	ld a, BATTLEMENU_RUN
	ld [wBattleMenuCursorPosition], a
	jr nz, .loop ; wasn't on RUN yet: show the menu again with the cursor on RUN
	ld [wMenuCursorPosition], a
	call ExitMenu
	ret

.CanRunWithB:
; carry if this is a wild battle the player is allowed to run from
	ld a, [wLinkMode]
	and a
	ret nz
	ld a, [wBattleMode]
	cp WILD_BATTLE
	jr nz, .no
	ld a, [wBattleType]
	cp BATTLETYPE_TRAP
	jr z, .no
	cp BATTLETYPE_CELEBI
	jr z, .no
	cp BATTLETYPE_FORCESHINY
	jr z, .no
	cp BATTLETYPE_SUICUNE
	jr z, .no
	ld a, [wEnemySubStatus5]
	bit SUBSTATUS_CANT_RUN, a
	jr nz, .no
	ld a, [wPlayerWrapCount]
	and a
	jr nz, .no
	scf
	ret
.no
	and a
	ret

SafariBattleMenu: ; unreferenced
	ld hl, SafariBattleMenuHeader
	call LoadMenuHeader
	jr CommonBattleMenu

ContestBattleMenu:
	ld hl, ContestBattleMenuHeader
	call LoadMenuHeader
	; fallthrough

CommonBattleMenu:
	ld a, [wBattleMenuCursorPosition]
	ld [wMenuCursorPosition], a
	call _2DMenu
	ld a, [wMenuCursorPosition]
	ld [wBattleMenuCursorPosition], a
	call ExitMenu
	ret

BattleMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 8, 12, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR ; flags (B jumps to RUN, see LoadBattleMenu)
	dn 2, 2 ; rows, columns
	db 6 ; spacing
	dba .Text
	dbw BANK(@), NULL

.Text:
	db "Fight@"
	db "<PKMN>@"
	db "Pack@"
	db "Run@"

SafariBattleMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 12, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR | STATICMENU_DISABLE_B ; flags
	dn 2, 2 ; rows, columns
	db 11 ; spacing
	dba .Text
	dba .PrintSafariBallsRemaining

.Text:
	db "サファりボール×　　@" ; "SAFARI BALL×  @"
	db "エサをなげる@" ; "THROW BAIT"
	db "いしをなげる@" ; "THROW ROCK"
	db "にげる@" ; "RUN"

.PrintSafariBallsRemaining:
	hlcoord 17, 13
	ld de, wSafariBallsRemaining
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2
	call PrintNum
	ret

ContestBattleMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 2, 12, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR | STATICMENU_DISABLE_B ; flags
	dn 2, 2 ; rows, columns
	db 12 ; spacing
	dba .Text
	dba .PrintParkBallsRemaining

.Text:
	db "Fight@"
	db "<PKMN>@"
	db "Parkball×  @"
	db "Run@"

.PrintParkBallsRemaining:
	hlcoord 13, 16
	ld de, wParkBallsRemaining
	lb bc, PRINTNUM_LEADINGZEROS | 1, 2
	call PrintNum
	ret
