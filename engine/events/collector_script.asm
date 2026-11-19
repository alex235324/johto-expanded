; Script and text for the New Bark Town collector (maps/NewBarkCollectorsHouse.asm).
; Lives here instead of in maps/ because the map script bank is full.

CollectorScript::
	faceplayer
	opentext
	checkevent EVENT_MET_NEW_BARK_COLLECTOR
	iftrue .Menu
	writetext CollectorIntroText
	promptbutton
	setevent EVENT_MET_NEW_BARK_COLLECTOR
.Menu:
	writetext CollectorWhatWillItBeText
	loadmenu .MainMenuHeader
	verticalmenu
	closewindow
	ifequal 1, .Sell
	ifequal 2, .Buy
	sjump .Goodbye

.Sell:
	writetext CollectorWhichMonText
	promptbutton
	special CollectorSelectMon
	ifequal 1, .Menu ; cancelled
	ifequal 2, .LastMon
	ifequal 3, .Egg
	ifequal 4, .Mail
	ifequal 5, .LastMon
	writetext CollectorOfferText
	promptbutton
	readmem wCollectorBonus
	iffalse .NoBonus
	writetext CollectorWorthText
	promptbutton
	readmem wCollectorLevelBonus
	iffalse .HappinessBonusOnly
	readmem wCollectorHappyBonus
	iffalse .LevelBonusOnly
	writetext CollectorBothBonusesText
	promptbutton
	sjump .NoBonus

.LevelBonusOnly:
	writetext CollectorLevelBonusText
	promptbutton
	sjump .NoBonus

.HappinessBonusOnly:
	writetext CollectorHappinessBonusText
	promptbutton
.NoBonus:
	readmem wCollectorShiny
	iffalse .AskDeal
	writetext CollectorShinyText
	promptbutton
.AskDeal:
	writetext CollectorDealText
	yesorno
	iffalse .Menu
	special CollectorTakeMon
	ifequal 1, .BagFull
	ifequal 2, .ItemReturned
.Paid:
	playsound SFX_TRANSACTION
	waitsfx
	writetext CollectorPaidText
	promptbutton
	sjump .Menu

.ItemReturned:
	writetext CollectorItemReturnedText
	promptbutton
	sjump .Paid

.BagFull:
	writetext CollectorBagFullText
	promptbutton
	sjump .Menu

.LastMon:
	writetext CollectorLastMonText
	promptbutton
	sjump .Menu

.Egg:
	writetext CollectorEggText
	promptbutton
	sjump .Menu

.Mail:
	writetext CollectorMailText
	promptbutton
	sjump .Menu

.Buy:
	writetext CollectorWhichCategoryText
	loadmenu .ShopMenuHeader
	verticalmenu
	closewindow
	ifequal 4, .Menu
	ifequal 0, .Menu
	special CollectorShop
	sjump .Menu

.Goodbye:
	writetext CollectorGoodbyeText
	waitbutton
	closetext
	end

.MainMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 4, 14, TEXTBOX_Y - 1
	dw .MainMenuData
	db 1 ; default option

.MainMenuData:
	db STATICMENU_CURSOR ; flags
	db 3 ; items
	db "Sell #mon@"
	db "Buy Items@"
	db "Cancel@"

.ShopMenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 0, 2, 13, TEXTBOX_Y - 1
	dw .ShopMenuData
	db 1 ; default option

.ShopMenuData:
	db STATICMENU_CURSOR ; flags
	db 4 ; items
	db "Held Items@"
	db "Training@"
	db "Special@"
	db "Cancel@"

CollectorIntroText:
	text "Oho! A trainer!"
	line "Do come in!"

	para "I collect #mon."
	line "All of them! The"

	para "rare, the common,"
	line "the legendary…"
	cont "I adore them all!"

	para "Bring me #mon"
	line "and I'll pay you"
	cont "in my own coin:"
	cont "Collector Tokens!"

	para "The rarer the"
	line "#mon, the more"
	cont "Tokens I'll pay."

	para "A legend? Why,"
	line "that's a fortune!"

	para "Spend your Tokens"
	line "on my treasures."

	para "Use my PC there to"
	line "fetch #mon from"
	cont "your Boxes."
	done

CollectorWhatWillItBeText:
	text "You have @"
	text_decimal wCollectorTokens, 2, 4
	text_start
	line "Tokens. Well?"
	done

CollectorWhichMonText:
	text "Show me what you"
	line "have!"
	done

CollectorOfferText:
	text "Ah, @"
	text_ram wStringBuffer1
	text "!"
	line "I'll give you @"
	text_decimal wCollectorOffer, 2, 3
	text_start
	cont "Tokens for it!"
	done

CollectorWorthText:
	text_ram wStringBuffer4
	text_start
	line "is worth @"
	text_decimal wCollectorBase, 1, 2
	text " Tokens…"
	done

CollectorBothBonusesText:
	text "But I'll give @"
	text_decimal wCollectorLevelBonus, 1, 2
	text_start
	line "more for its level"

	para "and @"
	text_decimal wCollectorHappyBonus, 1, 1
	text " more for"
	line "its happiness!"
	done

CollectorLevelBonusText:
	text "But I'll give @"
	text_decimal wCollectorLevelBonus, 1, 2
	text_start
	line "more for its level!"
	done

CollectorHappinessBonusText:
	text "But I'll give @"
	text_decimal wCollectorHappyBonus, 1, 1
	text_start
	line "more for its"
	cont "happiness!"
	done

CollectorShinyText:
	text "And it's shiny!"
	line "That doubles it!"
	done

CollectorDealText:
	text "Do we have a deal?"
	done

CollectorPaidText:
	text "Splendid! It shall"
	line "live in luxury."

	para "Here are your"
	line "Tokens!"
	done

CollectorItemReturnedText:
	text "Oh, it was holding"
	line "something. I put"
	cont "it in your Bag."
	done

CollectorBagFullText:
	text "It's holding an"
	line "item, and your Bag"
	cont "has no room for"
	cont "it. Make room!"
	done

CollectorLastMonText:
	text "And leave you with"
	line "no #mon to"
	cont "fight with? Never!"
	done

CollectorEggText:
	text "An Egg? I collect"
	line "#mon, not"
	cont "breakfast!"
	done

CollectorMailText:
	text "It's holding Mail."
	line "Do take that off"
	cont "first."
	done

CollectorWhichCategoryText:
	text "My treasures!"
	line "Which shelf?"
	done

CollectorGoodbyeText:
	text "Do come again!"
	line "Bring rare ones!"
	done

