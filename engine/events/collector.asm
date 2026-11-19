; The eccentric collector in New Bark Town (maps/NewBarkCollectorsHouse.asm).
; He buys Pokémon for Collector Tokens (wCollectorTokens) and sells
; battle items for them.
;   Offer = species value (data/events/collector_values.asm)
;         + floor(level / 20)
;         + min(5, floor(max(0, happiness - 70) / 37))
;   doubled for shinies. Max: (60 + 5 + 5) * 2 = 140.
; Items he sells fetch at most 50 yen per Token at a Mart
; (CollectorCapSellPrice), so Tokens can't be farmed through yen.

DEF COLLECTOR_MAX_TOKENS EQU 9999
DEF COLLECTOR_LEVELS_PER_TOKEN EQU 20 ; Lv 100: +5
DEF COLLECTOR_HAPPINESS_BASELINE EQU 70 ; a fresh catch (70) or less gets 0
DEF COLLECTOR_HAPPINESS_PER_TOKEN EQU 37 ; above the baseline; 255 happiness: +5
DEF COLLECTOR_MAX_HAPPINESS_BONUS EQU 5
DEF COLLECTOR_SELL_YEN_PER_TOKEN EQU 50 ; Mart sell price cap for his items

; wCollectorShopCategory (CollectorPrizeMenu.MenuHeaders)
	const_def
	const COLLECTOR_SHELF_HELD_ITEMS
	const COLLECTOR_SHELF_TRAINING
	const COLLECTOR_SHELF_SPECIAL
	const COLLECTOR_SHELF_TRAINING_CHAMPION ; Training + Rare Candy, after the Elite Four

; CollectorSelectMon return values (wScriptVar)
	const_def
	const COLLECTOR_SELECT_OK       ; offer in wCollectorOffer, nickname in wStringBuffer1
	const COLLECTOR_SELECT_CANCEL
	const COLLECTOR_SELECT_LAST_MON
	const COLLECTOR_SELECT_EGG
	const COLLECTOR_SELECT_MAIL
	const COLLECTOR_SELECT_LAST_ALIVE

; CollectorTakeMon return values (wScriptVar)
	const_def
	const COLLECTOR_TAKE_OK
	const COLLECTOR_TAKE_BAG_FULL     ; its held item didn't fit; nothing happened
	const COLLECTOR_TAKE_ITEM_RETURNED

CollectorSelectMon:
	ld a, [wPartyCount]
	cp 2
	ld a, COLLECTOR_SELECT_LAST_MON
	jr c, .done
	ld b, PARTYMENUACTION_GIVE_MON
	farcall SelectTradeOrDayCareMon
	ld a, COLLECTOR_SELECT_CANCEL
	jr c, .done
	ld a, [wCurPartySpecies]
	cp EGG
	ld a, COLLECTOR_SELECT_EGG
	jr z, .done
	farcall CheckCurPartyMonFainted
	ld a, COLLECTOR_SELECT_LAST_ALIVE
	jr c, .done
	ld a, MON_ITEM
	call CollectorGetPartyMonField
	ld d, [hl]
	farcall ItemIsMail
	ld a, COLLECTOR_SELECT_MAIL
	jr c, .done

	call CollectorGetOffer
	ld hl, wPartyMonNicknames
	ld a, [wCurPartyMon]
	call GetNickname
	ld a, COLLECTOR_SELECT_OK
.done
	ld [wScriptVar], a
	ret

; hl = field a of the current party mon
CollectorGetPartyMonField:
	push bc
	ld hl, wPartyMon1
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [wCurPartyMon]
	ld bc, PARTYMON_STRUCT_LENGTH
	call AddNTimes
	pop bc
	ret

CollectorGetOffer:
; Fills wCollectorBase, wCollectorLevelBonus, wCollectorHappyBonus,
; wCollectorBonus (their sum), wCollectorShiny and wCollectorOffer
; (= base + bonuses, doubled for shinies), and the species name in wStringBuffer4.
	ld a, [wCurPartySpecies]
	ld [wNamedObjectIndex], a
	call GetPokemonName
	ld hl, wStringBuffer1
	ld de, wStringBuffer4
	ld bc, MON_NAME_LENGTH
	call CopyBytes

	ld a, [wCurPartySpecies]
	call GetPokemonIndexFromID
	dec hl
	ld de, CollectorValues
	add hl, de
	ld a, [hl]
	ld [wCollectorBase], a

	; +1 per COLLECTOR_LEVELS_PER_TOKEN levels
	ld a, MON_LEVEL
	call CollectorGetPartyMonField
	ld a, [hl]
	ld d, COLLECTOR_LEVELS_PER_TOKEN
	call .Divide
	ld a, b
	ld [wCollectorLevelBonus], a
	; +1 per COLLECTOR_HAPPINESS_PER_TOKEN happiness above
	; COLLECTOR_HAPPINESS_BASELINE (max +COLLECTOR_MAX_HAPPINESS_BONUS)
	ld a, MON_HAPPINESS
	call CollectorGetPartyMonField
	ld a, [hl]
	sub COLLECTOR_HAPPINESS_BASELINE
	jr nc, .above_baseline
	xor a
.above_baseline
	ld d, COLLECTOR_HAPPINESS_PER_TOKEN
	call .Divide
	ld a, b
	cp COLLECTOR_MAX_HAPPINESS_BONUS + 1
	jr c, .got_happiness_bonus
	ld a, COLLECTOR_MAX_HAPPINESS_BONUS
.got_happiness_bonus
	ld [wCollectorHappyBonus], a
	ld hl, wCollectorLevelBonus
	add [hl]
	ld [wCollectorBonus], a
	ld hl, wCollectorBase
	add [hl]
	ld [wCollectorOffer + 1], a
	xor a
	ld [wCollectorOffer], a
	ld [wCollectorShiny], a

	ld a, MON_DVS
	call CollectorGetPartyMonField
	ld b, h
	ld c, l
	farcall CheckShininess
	ret nc
	; shinies are worth double (base + bonus <= 60 + 5 + 5 = 70, so 140 fits a byte)
	ld a, TRUE
	ld [wCollectorShiny], a
	ld hl, wCollectorOffer + 1
	sla [hl]
	ret

.Divide:
; b = a / d
	ld b, 0
.divide_loop
	cp d
	ret c
	sub d
	inc b
	jr .divide_loop

CollectorTakeMon:
	ld c, COLLECTOR_TAKE_OK
	ld a, MON_ITEM
	call CollectorGetPartyMonField
	ld a, [hl]
	and a
	jr z, .take
	ld [wCurItem], a
	ld a, 1
	ld [wItemQuantityChange], a
	ld hl, wNumItems
	call ReceiveItem
	ld a, COLLECTOR_TAKE_BAG_FULL
	jr nc, .done
	ld c, COLLECTOR_TAKE_ITEM_RETURNED

.take
	push bc
	xor a ; REMOVE_PARTY
	ld [wPokemonWithdrawDepositParameter], a
	farcall RemoveMonFromPartyOrBox
	ld a, [wCollectorOffer]
	ld d, a
	ld a, [wCollectorOffer + 1]
	ld e, a
	call CollectorAddTokens
	pop bc
	ld a, c
.done
	ld [wScriptVar], a
	ret

; add de to wCollectorTokens, capped at COLLECTOR_MAX_TOKENS
CollectorAddTokens:
	ld a, [wCollectorTokens]
	ld h, a
	ld a, [wCollectorTokens + 1]
	ld l, a
	add hl, de
	jr c, .cap
	push hl
	ld bc, -(COLLECTOR_MAX_TOKENS + 1)
	add hl, bc
	pop hl
	jr nc, .store
.cap
	ld hl, COLLECTOR_MAX_TOKENS
.store
	ld a, h
	ld [wCollectorTokens], a
	ld a, l
	ld [wCollectorTokens + 1], a
	ret

; Called from SelectQuantityToSell (engine/items/buy_sell_toss.asm) with
; de = wCurItem's item price. If the Collector sells wCurItem, lower de to
; its token price * COLLECTOR_SELL_YEN_PER_TOKEN * 2 (Marts pay half the
; item price), never raising it. Only the sell path calls this, so buy
; prices are unchanged. Caps follow CollectorPrizes, so they track its prices.
CollectorCapSellPrice:
	push bc
	push hl
	ld a, [wCurItem]
	ld c, a
	ld hl, CollectorPrizes
	ld b, (CollectorPrizesEnd - CollectorPrizes) / 2
.loop
	ld a, [hli]
	cp c
	jr z, .found
	inc hl
	dec b
	jr nz, .loop
	jr .done

.found
	ld a, [hl] ; token price
	push de
	ld hl, 0
	ld de, COLLECTOR_SELL_YEN_PER_TOKEN * 2
	and a
	jr z, .got_cap
.multiply
	add hl, de
	dec a
	jr nz, .multiply
.got_cap
	pop de
	; de = min(de, hl)
	ld a, e
	sub l
	ld a, d
	sbc h
	jr c, .done
	ld d, h
	ld e, l
.done
	pop hl
	pop bc
	ret

; wScriptVar: 1 = held items, 2 = training, 3 = special
CollectorShop:
	ld a, [wScriptVar]
	dec a
	cp COLLECTOR_SHELF_TRAINING
	jr nz, .got_shelf
	; Rare Candy is only for champions
	ld de, EVENT_BEAT_ELITE_FOUR
	ld b, CHECK_FLAG
	call EventFlagAction ; c = flag
	ld a, c
	and a
	ld a, COLLECTOR_SHELF_TRAINING
	jr z, .got_shelf
	ld a, COLLECTOR_SHELF_TRAINING_CHAMPION
.got_shelf
	ld [wCollectorShopCategory], a
	xor a
	ld [wMenuScrollPosition], a
	ld a, 1
	ld [wMenuSelection], a
	ld hl, .BoxHeader
	call LoadMenuHeader
	call CollectorLoadBalanceBox
	ld hl, .WhichText
	call PrintText
	jr .menu

.loop
	ld hl, .WhichText
	call BuenaPrintText
.menu
	call DelayFrame
	call UpdateSprites
	call CollectorPrintBalance
	call CollectorPrizeMenu
	jr z, .done
	ld [wMenuSelectionQuantity], a
	call CollectorGetPrize
	ld a, [hl]
	ld [wNamedObjectIndex], a
	call GetItemName
	ld hl, .IsThatRightText
	call BuenaPrintText
	call YesNoBox
	jr c, .loop

	ld a, [wMenuSelectionQuantity]
	call CollectorGetPrize
	; enough tokens? (prices fit in one byte)
	inc hl
	ld a, [wCollectorTokens]
	and a
	jr nz, .can_afford
	ld a, [wCollectorTokens + 1]
	cp [hl]
	jr c, .not_enough
.can_afford
	dec hl
	ld a, [hli]
	push hl
	ld [wCurItem], a
	ld a, 1
	ld [wItemQuantityChange], a
	ld hl, wNumItems
	call ReceiveItem
	pop hl
	jr nc, .bag_full
	ld a, [wCollectorTokens + 1]
	sub [hl]
	ld [wCollectorTokens + 1], a
	ld a, [wCollectorTokens]
	sbc 0
	ld [wCollectorTokens], a
	call CollectorPrintBalance
	ld de, SFX_TRANSACTION
	call PlaySFX
	ld hl, .HereYouGoText
	jr .print

.not_enough
	ld hl, .NotEnoughText
	jr .print

.bag_full
	ld hl, .NoRoomText
.print
	call BuenaPrintText
	jr .loop

.done
	call CloseWindow
	call CloseWindow
	ld hl, .ComeAgainText
	call PrintText
	call JoyWaitAorB
	call PlayClickSFX
	ret

.BoxHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 0, 19, TEXTBOX_Y - 1

.WhichText:
	text "What catches your"
	line "eye, hmm?"
	done

.IsThatRightText:
	text_ram wStringBuffer1
	text "?"
	line "Splendid choice!"
	done

.HereYouGoText:
	text "Yours! Treasure"
	line "it as I would."
	para ""
	done

.NotEnoughText:
	text "Alas, you lack the"
	line "Tokens for that."
	para ""
	done

.NoRoomText:
	text "Your Bag has no"
	line "room for it!"
	para ""
	done

.ComeAgainText:
	text "Do return with"
	line "more treasures!"
	done

CollectorLoadBalanceBox:
	ld hl, CollectorBalanceMenuHeader
	jp LoadMenuHeader

CollectorPrintBalance:
	xor a
	ldh [hBGMapMode], a
	ld hl, CollectorBalanceMenuHeader
	call CopyMenuHeader
	call MenuBox
	call UpdateSprites
	call MenuBoxCoord2Tile
	ld bc, SCREEN_WIDTH + 1
	add hl, bc
	ld de, .TokensString
	call PlaceString
	ld h, b
	ld l, c
	inc hl
	ld de, wCollectorTokens
	lb bc, 2, 4
	call PrintNum
	ret

.TokensString:
	db "Tokens@"

CollectorBalanceMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 11, 12, 13

; returns z if cancelled, else a = 1-based index into CollectorPrizes
CollectorPrizeMenu:
	ld a, [wCollectorShopCategory]
	ld c, a
	ld b, 0
	ld hl, .MenuHeaders
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyMenuHeader
	ld a, [wMenuSelection]
	ld [wMenuCursorPosition], a
	xor a
	ld [wWhichIndexSet], a
	ldh [hBGMapMode], a
	call InitScrollingMenu
	call UpdateSprites
	call ScrollingMenu
	ld a, [wMenuSelection]
	ld c, a
	ld a, [wMenuCursorY]
	ld [wMenuSelection], a
	ld a, [wMenuJoypad]
	cp PAD_B
	jr z, .cancel
	ld a, c
	and a
	ret z
	inc a ; -1 means CANCEL
	ret z
	ld a, c
	ret

.cancel
	xor a
	ret

.MenuHeaders:
; entries correspond to COLLECTOR_SHELF_* constants
	dw .HeldItemsHeader
	dw .TrainingHeader
	dw .SpecialHeader
	dw .TrainingChampionHeader

MACRO collector_prize_menu
.\1Header:
	db MENU_BACKUP_TILES ; flags
	menu_coords 1, 1, 18, 9
	dw .\1Data
	db 1 ; default option
	db 0
.\1Data:
	db SCROLLINGMENU_DISPLAY_ARROWS | SCROLLINGMENU_ENABLE_FUNCTION3 ; flags
	db 4, 13 ; rows, columns
	db SCROLLINGMENU_ITEMS_NORMAL ; item format
	dba Collector\1List
	dba .PrintItem
	dba .PrintPrice
	dba .PrintDescription
ENDM

	collector_prize_menu HeldItems
	collector_prize_menu Training
	collector_prize_menu TrainingChampion ; Training + Rare Candy
	collector_prize_menu Special

.PrintItem:
	ld a, [wMenuSelection]
	call CollectorGetPrize
	ld a, [hl]
	push de
	ld [wNamedObjectIndex], a
	call GetItemName
	pop hl
	jp PlaceString

.PrintDescription:
; the highlighted item's description replaces the prompt (like a mart)
	hlcoord TEXTBOX_INNERX, TEXTBOX_INNERY
	lb bc, TEXTBOX_INNERH - 1, TEXTBOX_INNERW
	call ClearBox
	ld a, [wMenuSelection]
	cp -1
	jr nz, .describe
	ld hl, .CancelText ; on CANCEL
	jp PrintTextboxText

.describe
	call CollectorGetPrize
	ld a, [hl]
	ld [wCurSpecies], a
	decoord TEXTBOX_INNERX, TEXTBOX_INNERY
	farcall PrintItemDescription
	ret

.CancelText:
	text "That's enough for"
	line "now, then?"
	done

.PrintPrice:
	ld a, [wMenuSelection]
	call CollectorGetPrize
	inc hl
	ld a, [hl]
	ld [wCollectorPrice], a
	ld h, d
	ld l, e
	ld de, wCollectorPrice
	lb bc, 1, 3
	jp PrintNum

; hl = CollectorPrizes entry a (1-based)
CollectorGetPrize:
	dec a
	ld hl, CollectorPrizes
	ld b, 0
	ld c, a
	add hl, bc
	add hl, bc
	ret

INCLUDE "data/items/collector_prizes.asm"

INCLUDE "data/events/collector_values.asm"
