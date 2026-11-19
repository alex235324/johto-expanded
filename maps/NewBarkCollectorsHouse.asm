	object_const_def
	const NEWBARKCOLLECTORSHOUSE_COLLECTOR

NewBarkCollectorsHouse_MapScripts:
	def_scene_scripts

	def_callbacks

NewBarkCollectorsHouseCollector:
	farsjump CollectorScript ; engine/events/collector_script.asm

NewBarkCollectorsHouseBookshelf:
	jumpstd MagazineBookshelfScript

NewBarkCollectorsHouse_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  2,  7, NEW_BARK_TOWN, 5
	warp_event  3,  7, NEW_BARK_TOWN, 5

	def_coord_events

	def_bg_events
	bg_event  0,  1, BGEVENT_READ, NewBarkCollectorsHouseBookshelf
	bg_event  1,  1, BGEVENT_READ, NewBarkCollectorsHouseBookshelf

	def_object_events
	object_event  5,  3, SPRITE_GENTLEMAN, SPRITEMOVEDATA_STANDING_LEFT, 0, 0, -1, -1, PAL_NPC_BROWN, OBJECTTYPE_SCRIPT, 0, NewBarkCollectorsHouseCollector, -1
