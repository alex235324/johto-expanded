	object_const_def
	const GUIDEGENTSHOUSE_GRAMPS

GuideGentsHouse_MapScripts:
	def_scene_scripts

	def_callbacks

GuideGentsHouseGuideGent:
	faceplayer
	opentext
	checkflag ENGINE_RUNNING_SHOES
	iftrue .HaveShoes
	writetext GuideGentsHouseShoesText
	promptbutton
	getstring STRING_BUFFER_4, .runningshoesname
	scall .ReceiveItem
	setflag ENGINE_RUNNING_SHOES
	setflag ENGINE_MAP_CARD ; for saves that got the Pokégear before it came with the map
	writetext GuideGentsHouseHowToRunText
	waitbutton
	closetext
	end

.HaveShoes:
	writetext GuideGentsHouseGuideGentText
	waitbutton
	closetext
	end

.ReceiveItem:
	jumpstd ReceiveItemScript
	end

.runningshoesname
	db "Running Shoes@"

GuideGentsHouseBookshelf:
	jumpstd MagazineBookshelfScript

GuideGentsHouseShoesText:
	text "Oh, it's you! I"
	line "forgot to give you"
	cont "something."
	done

GuideGentsHouseHowToRunText:
	text "<PLAYER> put on"
	line "the Running Shoes!"

	para "Hold down the B"
	line "Button to run!"
	done

GuideGentsHouseGuideGentText:
	text "When I was a wee"
	line "lad, I was a hot-"
	cont "shot trainer!"

	para "Here's a word of"
	line "advice: Catch lots"
	cont "of #mon!"

	para "Treat them all"
	line "with kindness!"
	done

GuideGentsHouse_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  2,  7, CHERRYGROVE_CITY, 4
	warp_event  3,  7, CHERRYGROVE_CITY, 4

	def_coord_events

	def_bg_events
	bg_event  0,  1, BGEVENT_READ, GuideGentsHouseBookshelf
	bg_event  1,  1, BGEVENT_READ, GuideGentsHouseBookshelf

	def_object_events
	object_event  2,  3, SPRITE_GRAMPS, SPRITEMOVEDATA_STANDING_RIGHT, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, GuideGentsHouseGuideGent, EVENT_GUIDE_GENT_VISIBLE_IN_CHERRYGROVE
