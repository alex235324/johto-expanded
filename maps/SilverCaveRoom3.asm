	object_const_def
	const SILVERCAVEROOM3_RED

SilverCaveRoom3_MapScripts:
	def_scene_scripts

	def_callbacks
	callback MAPCALLBACK_OBJECTS, SilverCaveRoom3RedCallback

SilverCaveRoom3RedCallback:
; once beaten, Red is back every time you enter for a rematch
	checkevent EVENT_BEAT_RED
	iffalse .Done
	appear SILVERCAVEROOM3_RED
.Done:
	endcallback

Red:
	special FadeOutMusic
	faceplayer
	opentext
	writetext RedSeenText
	waitbutton
	closetext
	winlosstext RedWinLossText, RedWinLossText
	loadtrainer RED, RED1
	startbattle
	dontrestartmapmusic
	reloadmapafterbattle
	special FadeOutMusic
; every win earns one more starter from Elm's lab
	readmem wRedStarterPicks
	ifequal 255, .GotPick
	addval 1
	writemem wRedStarterPicks
.GotPick:
	opentext
	writetext RedLeavesText
	waitbutton
	closetext
	special FadeOutToBlack
	special ReloadSpritesNoPalettes
	disappear SILVERCAVEROOM3_RED
	pause 15
	special FadeInFromBlack
	pause 30
	special HealParty
	reanchormap
	opentext
	writetext RedStarterPickText
	waitbutton
	checkevent EVENT_BEAT_RED
	iftrue .Rematch
	setevent EVENT_BEAT_RED
; the credits return to the title screen without saving, so save first
; or the pick (and the rematches) would be lost
	writetext RedSaveBeforeCreditsText
	waitbutton
	special TryQuickSave
	closetext
	credits
	end

.Rematch:
	closetext
	end

RedSeenText:
	text "<……>"
	line "<……>"
	done

RedWinLossText:
	text "…"
	done

RedLeavesText:
	text "<……>"
	line "<……>"
	done

RedStarterPickText:
	text "Prof.Elm has"
	line "another #mon"
	cont "waiting for you!"
	done

RedSaveBeforeCreditsText:
	text "Let's save your"
	line "progress first."
	done

SilverCaveRoom3_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  9, 33, SILVER_CAVE_ROOM_2, 2

	def_coord_events

	def_bg_events

	def_object_events
	object_event  9, 10, SPRITE_RED, SPRITEMOVEDATA_STANDING_UP, 0, 0, -1, -1, PAL_NPC_RED, OBJECTTYPE_SCRIPT, 0, Red, EVENT_RED_IN_MT_SILVER
