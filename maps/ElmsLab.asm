; After the first starter, each win against Red (wRedStarterPicks) lets the
; player take one more ball from the tables.
MACRO bonus_starter_ball
; \1 = species, \2 = event set once its ball is taken
	checkevent \2
	iftrue ElmsLabEmptyBallScript
	readmem wRedStarterPicks
	iffalse LookAtElmPokeBallScript
	pokepic \1
	cry \1
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, \1
	writetext ElmsLabTakeBonusStarterText
	yesorno
	iffalse ElmsLabBonusStarterNoScript
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke \1, 5, BERRY
	ifequal 2, ElmsLabBonusStarterNoRoomScript ; 0 = party, 1 = PC box, 2 = no room
	setevent \2
	sjump ElmsLabGotBonusStarterScript
ENDM

; Ball tables: $40 holds two balls; $42 = left one taken, $41 = right one
; taken, $06 = both taken. $43 holds one ball; $07 = taken.
MACRO redraw_ball_pair
; \1, \2 = block coords, \3 = left ball event, \4 = right ball event
	checkevent \3
	iftrue .left_taken\@
	checkevent \4
	iffalse .done\@
	changeblock \1, \2, $41
	sjump .done\@
.left_taken\@
	checkevent \4
	iftrue .both_taken\@
	changeblock \1, \2, $42
	sjump .done\@
.both_taken\@
	changeblock \1, \2, $06
.done\@
ENDM

MACRO redraw_ball_single
; \1, \2 = block coords, \3 = ball event
	checkevent \3
	iffalse .done\@
	changeblock \1, \2, $07
.done\@
ENDM

	object_const_def
	const ELMSLAB_ELM
	const ELMSLAB_ELMS_AIDE
	const ELMSLAB_OFFICER

ElmsLab_MapScripts:
	def_scene_scripts
	scene_script ElmsLabMeetElmScene, SCENE_ELMSLAB_MEET_ELM
	scene_script ElmsLabNoop1Scene,   SCENE_ELMSLAB_CANT_LEAVE
	scene_script ElmsLabNoop2Scene,   SCENE_ELMSLAB_NOOP
	scene_script ElmsLabNoop3Scene,   SCENE_ELMSLAB_MEET_OFFICER
	scene_script ElmsLabNoop4Scene,   SCENE_ELMSLAB_UNUSED
	scene_script ElmsLabNoop5Scene,   SCENE_ELMSLAB_AIDE_GIVES_POTION
	scene_const SCENE_ELMSLAB_AIDE_GIVES_POKE_BALLS

	def_callbacks
	callback MAPCALLBACK_OBJECTS, ElmsLabMoveElmCallback
	callback MAPCALLBACK_TILES, ElmsLabStarterBallsCallback

ElmsLabMeetElmScene:
	sdefer ElmsLabWalkUpToElmScript
	end

ElmsLabNoop1Scene:
	end

ElmsLabNoop2Scene:
	end

ElmsLabNoop3Scene:
	end

ElmsLabNoop4Scene:
	end

ElmsLabNoop5Scene:
	end

ElmsLabMoveElmCallback:
	checkscene
	iftrue .Skip ; not SCENE_ELMSLAB_MEET_ELM
	moveobject ELMSLAB_ELM, 3, 4
.Skip:
	endcallback

ElmsLabWalkUpToElmScript:
	applymovement PLAYER, ElmsLab_WalkUpToElmMovement
	showemote EMOTE_SHOCK, ELMSLAB_ELM, 15
	turnobject ELMSLAB_ELM, RIGHT
	opentext
	writetext ElmText_Intro
.MustSayYes:
	yesorno
	iftrue .ElmGetsEmail
	writetext ElmText_Refused
	sjump .MustSayYes

.ElmGetsEmail:
	writetext ElmText_Accepted
	promptbutton
	writetext ElmText_ResearchAmbitions
	waitbutton
	closetext
	playsound SFX_GLASS_TING
	pause 30
	showemote EMOTE_SHOCK, ELMSLAB_ELM, 10
	turnobject ELMSLAB_ELM, DOWN
	opentext
	writetext ElmText_GotAnEmail
	waitbutton
	closetext
	opentext
	turnobject ELMSLAB_ELM, RIGHT
	writetext ElmText_MissionFromMrPokemon
	waitbutton
	closetext
	applymovement ELMSLAB_ELM, ElmsLab_ElmToDefaultPositionMovement1
	turnobject PLAYER, UP
	applymovement ELMSLAB_ELM, ElmsLab_ElmToDefaultPositionMovement2
	turnobject PLAYER, RIGHT
	opentext
	writetext ElmText_ChooseAPokemon
	waitbutton
	setscene SCENE_ELMSLAB_CANT_LEAVE
	closetext
	end

ProfElmScript:
	faceplayer
	opentext
	checkevent EVENT_GOT_SS_TICKET_FROM_ELM
	iftrue ElmCheckMasterBall
	checkevent EVENT_BEAT_ELITE_FOUR
	iftrue ElmGiveTicketScript
ElmCheckMasterBall:
	checkevent EVENT_GOT_MASTER_BALL_FROM_ELM
	iftrue ElmCheckEverstone
	checkflag ENGINE_RISINGBADGE
	iftrue ElmGiveMasterBallScript
ElmCheckEverstone:
	checkevent EVENT_GOT_EVERSTONE_FROM_ELM
	iftrue ElmScript_CallYou
	checkevent EVENT_SHOWED_TOGEPI_TO_ELM
	iftrue ElmGiveEverstoneScript
	checkevent EVENT_TOLD_ELM_ABOUT_TOGEPI_OVER_THE_PHONE
	iffalse ElmCheckTogepiEgg
	loadmonindex 1, TOGEPI
	special FindPartyMonThatSpeciesYourTrainerID
	iftrue ShowElmTogepiScript
	loadmonindex 2, TOGETIC
	special FindPartyMonThatSpeciesYourTrainerID
	iftrue ShowElmTogepiScript
	writetext ElmThoughtEggHatchedText
	waitbutton
	closetext
	end

ElmEggHatchedScript:
	loadmonindex 1, TOGEPI
	special FindPartyMonThatSpeciesYourTrainerID
	iftrue ShowElmTogepiScript
	loadmonindex 2, TOGETIC
	special FindPartyMonThatSpeciesYourTrainerID
	iftrue ShowElmTogepiScript
	sjump ElmCheckGotEggAgain

ElmCheckTogepiEgg:
	checkevent EVENT_GOT_TOGEPI_EGG_FROM_ELMS_AIDE
	iffalse ElmCheckGotEggAgain
	checkevent EVENT_TOGEPI_HATCHED
	iftrue ElmEggHatchedScript
ElmCheckGotEggAgain:
	checkevent EVENT_GOT_TOGEPI_EGG_FROM_ELMS_AIDE ; why are we checking it again?
	iftrue ElmWaitingEggHatchScript
	checkflag ENGINE_ZEPHYRBADGE
	iftrue ElmAideHasEggScript
	checkevent EVENT_GAVE_MYSTERY_EGG_TO_ELM
	iftrue ElmStudyingEggScript
	checkevent EVENT_GOT_MYSTERY_EGG_FROM_MR_POKEMON
	iftrue ElmAfterTheftScript
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iftrue ElmDescribesMrPokemonScript
	writetext ElmText_LetYourMonBattleIt
	waitbutton
	closetext
	end

LabTryToLeaveScript:
	turnobject ELMSLAB_ELM, DOWN
	opentext
	writetext LabWhereGoingText
	waitbutton
	closetext
	applymovement PLAYER, ElmsLab_CantLeaveMovement
	end

BulbasaurPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball BULBASAUR, EVENT_GOT_BULBASAUR_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic BULBASAUR
	cry BULBASAUR
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, BULBASAUR
	writetext TakeGrassStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 6, 2, $42
	reloadmappart
	setevent EVENT_GOT_BULBASAUR_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke BULBASAUR, 5, BERRY
	closetext
	applymovement PLAYER, AfterBulbasaurMovement
	sjump ElmDirectionsScript

CharmanderPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball CHARMANDER, EVENT_GOT_CHARMANDER_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic CHARMANDER
	cry CHARMANDER
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, CHARMANDER
	writetext TakeFireStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 6, 2, $41
	reloadmappart
	setevent EVENT_GOT_CHARMANDER_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke CHARMANDER, 5, BERRY
	closetext
	applymovement PLAYER, AfterCharmanderMovement
	sjump ElmDirectionsScript

SquirtlePokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball SQUIRTLE, EVENT_GOT_SQUIRTLE_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic SQUIRTLE
	cry SQUIRTLE
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, SQUIRTLE
	writetext TakeWaterStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 8, 2, $07
	reloadmappart
	setevent EVENT_GOT_SQUIRTLE_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke SQUIRTLE, 5, BERRY
	closetext
	applymovement PLAYER, AfterSquirtleMovement
	sjump ElmDirectionsScript

ChikoritaPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball CHIKORITA, EVENT_GOT_CHIKORITA_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic CHIKORITA
	cry CHIKORITA
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, CHIKORITA
	writetext TakeGrassStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 10, 2, $42
	reloadmappart
	setevent EVENT_GOT_CHIKORITA_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke CHIKORITA, 5, BERRY
	closetext
	applymovement PLAYER, AfterChikoritaMovement
	sjump ElmDirectionsScript

CyndaquilPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball CYNDAQUIL, EVENT_GOT_CYNDAQUIL_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic CYNDAQUIL
	cry CYNDAQUIL
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, CYNDAQUIL
	writetext TakeFireStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 10, 2, $41
	reloadmappart
	setevent EVENT_GOT_CYNDAQUIL_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke CYNDAQUIL, 5, BERRY
	closetext
	applymovement PLAYER, AfterCyndaquilMovement
	sjump ElmDirectionsScript

TotodilePokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball TOTODILE, EVENT_GOT_TOTODILE_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic TOTODILE
	cry TOTODILE
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, TOTODILE
	writetext TakeWaterStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 12, 2, $07
	reloadmappart
	setevent EVENT_GOT_TOTODILE_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke TOTODILE, 5, BERRY
	closetext
	applymovement PLAYER, AfterTotodileMovement
	sjump ElmDirectionsScript

TreeckoPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball TREECKO, EVENT_GOT_TREECKO_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic TREECKO
	cry TREECKO
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, TREECKO
	writetext TakeGrassStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 14, 2, $42
	reloadmappart
	setevent EVENT_GOT_TREECKO_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke TREECKO, 5, BERRY
	closetext
	applymovement PLAYER, AfterTreeckoMovement
	sjump ElmDirectionsScript

TorchicPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball TORCHIC, EVENT_GOT_TORCHIC_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic TORCHIC
	cry TORCHIC
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, TORCHIC
	writetext TakeFireStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 14, 2, $41
	reloadmappart
	setevent EVENT_GOT_TORCHIC_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke TORCHIC, 5, BERRY
	closetext
	applymovement PLAYER, AfterTorchicMovement
	sjump ElmDirectionsScript

MudkipPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball MUDKIP, EVENT_GOT_MUDKIP_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic MUDKIP
	cry MUDKIP
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, MUDKIP
	writetext TakeWaterStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 16, 2, $07
	reloadmappart
	setevent EVENT_GOT_MUDKIP_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke MUDKIP, 5, BERRY
	closetext
	applymovement PLAYER, AfterMudkipMovement
	sjump ElmDirectionsScript

TurtwigPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball TURTWIG, EVENT_GOT_TURTWIG_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic TURTWIG
	cry TURTWIG
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, TURTWIG
	writetext TakeGrassStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 10, 6, $42
	reloadmappart
	setevent EVENT_GOT_TURTWIG_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke TURTWIG, 5, BERRY
	closetext
	applymovement PLAYER, AfterTurtwigMovement
	sjump ElmDirectionsScript

ChimcharPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball CHIMCHAR, EVENT_GOT_CHIMCHAR_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic CHIMCHAR
	cry CHIMCHAR
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, CHIMCHAR
	writetext TakeFireStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 10, 6, $41
	reloadmappart
	setevent EVENT_GOT_CHIMCHAR_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke CHIMCHAR, 5, BERRY
	closetext
	applymovement PLAYER, AfterChimcharMovement
	sjump ElmDirectionsScript

PiplupPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball PIPLUP, EVENT_GOT_PIPLUP_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic PIPLUP
	cry PIPLUP
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, PIPLUP
	writetext TakeWaterStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 12, 6, $07
	reloadmappart
	setevent EVENT_GOT_PIPLUP_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke PIPLUP, 5, BERRY
	closetext
	applymovement PLAYER, AfterPiplupMovement
	sjump ElmDirectionsScript

SnivyPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball SNIVY, EVENT_GOT_SNIVY_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic SNIVY
	cry SNIVY
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, SNIVY
	writetext TakeGrassStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 14, 6, $42
	reloadmappart
	setevent EVENT_GOT_SNIVY_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke SNIVY, 5, BERRY
	closetext
	applymovement PLAYER, AfterSnivyMovement
	sjump ElmDirectionsScript

TepigPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball TEPIG, EVENT_GOT_TEPIG_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic TEPIG
	cry TEPIG
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, TEPIG
	writetext TakeFireStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 14, 6, $41
	reloadmappart
	setevent EVENT_GOT_TEPIG_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke TEPIG, 5, BERRY
	closetext
	applymovement PLAYER, AfterTepigMovement
	sjump ElmDirectionsScript

OshawottPokeBallScript:
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iffalse .Initial
	bonus_starter_ball OSHAWOTT, EVENT_GOT_OSHAWOTT_FROM_ELM
.Initial:
	turnobject ELMSLAB_ELM, DOWN
	reanchormap
	pokepic OSHAWOTT
	cry OSHAWOTT
	waitbutton
	closepokepic
	opentext
	getmonname STRING_BUFFER_3, OSHAWOTT
	writetext TakeWaterStarterText
	yesorno
	iffalse DidntChooseStarterScript
	changeblock 16, 6, $07
	reloadmappart
	setevent EVENT_GOT_OSHAWOTT_FROM_ELM
	writetext ChoseStarterText
	promptbutton
	waitsfx
	writetext ReceivedStarterText
	playsound SFX_CAUGHT_MON
	waitsfx
	promptbutton
	givepoke OSHAWOTT, 5, BERRY
	closetext
	applymovement PLAYER, AfterOshawottMovement
	sjump ElmDirectionsScript

ElmsLabStarterBallsCallback:
; redraw the tables without every ball the player has taken
	redraw_ball_pair    6, 2, EVENT_GOT_BULBASAUR_FROM_ELM, EVENT_GOT_CHARMANDER_FROM_ELM
	redraw_ball_single  8, 2, EVENT_GOT_SQUIRTLE_FROM_ELM
	redraw_ball_pair   10, 2, EVENT_GOT_CHIKORITA_FROM_ELM, EVENT_GOT_CYNDAQUIL_FROM_ELM
	redraw_ball_single 12, 2, EVENT_GOT_TOTODILE_FROM_ELM
	redraw_ball_pair   14, 2, EVENT_GOT_TREECKO_FROM_ELM, EVENT_GOT_TORCHIC_FROM_ELM
	redraw_ball_single 16, 2, EVENT_GOT_MUDKIP_FROM_ELM
	redraw_ball_pair   10, 6, EVENT_GOT_TURTWIG_FROM_ELM, EVENT_GOT_CHIMCHAR_FROM_ELM
	redraw_ball_single 12, 6, EVENT_GOT_PIPLUP_FROM_ELM
	redraw_ball_pair   14, 6, EVENT_GOT_SNIVY_FROM_ELM, EVENT_GOT_TEPIG_FROM_ELM
	redraw_ball_single 16, 6, EVENT_GOT_OSHAWOTT_FROM_ELM
	endcallback

ElmsLabRedrawStarterBallsScript:
	redraw_ball_pair    6, 2, EVENT_GOT_BULBASAUR_FROM_ELM, EVENT_GOT_CHARMANDER_FROM_ELM
	redraw_ball_single  8, 2, EVENT_GOT_SQUIRTLE_FROM_ELM
	redraw_ball_pair   10, 2, EVENT_GOT_CHIKORITA_FROM_ELM, EVENT_GOT_CYNDAQUIL_FROM_ELM
	redraw_ball_single 12, 2, EVENT_GOT_TOTODILE_FROM_ELM
	redraw_ball_pair   14, 2, EVENT_GOT_TREECKO_FROM_ELM, EVENT_GOT_TORCHIC_FROM_ELM
	redraw_ball_single 16, 2, EVENT_GOT_MUDKIP_FROM_ELM
	redraw_ball_pair   10, 6, EVENT_GOT_TURTWIG_FROM_ELM, EVENT_GOT_CHIMCHAR_FROM_ELM
	redraw_ball_single 12, 6, EVENT_GOT_PIPLUP_FROM_ELM
	redraw_ball_pair   14, 6, EVENT_GOT_SNIVY_FROM_ELM, EVENT_GOT_TEPIG_FROM_ELM
	redraw_ball_single 16, 6, EVENT_GOT_OSHAWOTT_FROM_ELM
	reloadmappart
	end

ElmsLabEmptyBallScript:
	end

ElmsLabGotBonusStarterScript:
	readmem wRedStarterPicks
	addval -1
	writemem wRedStarterPicks
	closetext
	sjump ElmsLabRedrawStarterBallsScript

ElmsLabBonusStarterNoScript:
	writetext ElmsLabBonusStarterNoText
	waitbutton
	closetext
	end

ElmsLabBonusStarterNoRoomScript:
	writetext ElmsLabBonusStarterNoRoomText
	waitbutton
	closetext
	end

DidntChooseStarterScript:
	writetext DidntChooseStarterText
	waitbutton
	closetext
	end

ElmDirectionsScript:
	turnobject PLAYER, UP
	opentext
	writetext ElmDirectionsText1
	waitbutton
	closetext
	addcellnum PHONE_ELM
	opentext
	writetext GotElmsNumberText
	playsound SFX_REGISTER_PHONE_NUMBER
	waitsfx
	waitbutton
	closetext
	turnobject ELMSLAB_ELM, LEFT
	opentext
	writetext ElmDirectionsText2
	waitbutton
	closetext
	turnobject ELMSLAB_ELM, DOWN
	opentext
	writetext ElmDirectionsText3
	waitbutton
	closetext
	setevent EVENT_GOT_A_POKEMON_FROM_ELM
	setevent EVENT_RIVAL_CHERRYGROVE_CITY
	setscene SCENE_ELMSLAB_AIDE_GIVES_POTION
	setmapscene NEW_BARK_TOWN, SCENE_NEWBARKTOWN_NOOP
	end

ElmDescribesMrPokemonScript:
	writetext ElmDescribesMrPokemonText
	waitbutton
	closetext
	end

LookAtElmPokeBallScript:
	opentext
	writetext ElmPokeBallText
	waitbutton
	closetext
	end

ElmsLabHealingMachine:
	opentext
	checkevent EVENT_GOT_A_POKEMON_FROM_ELM
	iftrue .CanHeal
	writetext ElmsLabHealingMachineText1
	waitbutton
	closetext
	end

.CanHeal:
	writetext ElmsLabHealingMachineText2
	yesorno
	iftrue ElmsLabHealingMachine_HealParty
	closetext
	end

ElmsLabHealingMachine_HealParty:
	special StubbedTrainerRankings_Healings
	special HealParty
	playmusic MUSIC_NONE
	setval HEALMACHINE_ELMS_LAB
	special HealMachineAnim
	pause 30
	special RestartMapMusic
	closetext
	end

ElmAfterTheftDoneScript:
	waitbutton
	closetext
	end

ElmAfterTheftScript:
	writetext ElmAfterTheftText1
	checkitem MYSTERY_EGG
	iffalse ElmAfterTheftDoneScript
	promptbutton
	writetext ElmAfterTheftText2
	waitbutton
	takeitem MYSTERY_EGG
	scall ElmJumpBackScript1
	writetext ElmAfterTheftText3
	waitbutton
	scall ElmJumpBackScript2
	writetext ElmAfterTheftText4
	promptbutton
	writetext ElmAfterTheftText5
	promptbutton
	setevent EVENT_GAVE_MYSTERY_EGG_TO_ELM
	setflag ENGINE_MOBILE_SYSTEM
	setmapscene ROUTE_29, SCENE_ROUTE29_CATCH_TUTORIAL
	clearevent EVENT_ROUTE_30_YOUNGSTER_JOEY
	setevent EVENT_ROUTE_30_BATTLE
	writetext ElmAfterTheftText6
	waitbutton
	closetext
	setscene SCENE_ELMSLAB_AIDE_GIVES_POKE_BALLS
	end

ElmStudyingEggScript:
	writetext ElmStudyingEggText
	waitbutton
	closetext
	end

ElmAideHasEggScript:
	writetext ElmAideHasEggText
	waitbutton
	closetext
	end

ElmWaitingEggHatchScript:
	writetext ElmWaitingEggHatchText
	waitbutton
	closetext
	end

ShowElmTogepiScript:
	writetext ShowElmTogepiText1
	waitbutton
	closetext
	showemote EMOTE_SHOCK, ELMSLAB_ELM, 15
	setevent EVENT_SHOWED_TOGEPI_TO_ELM
	opentext
	writetext ShowElmTogepiText2
	promptbutton
	writetext ShowElmTogepiText3
	promptbutton
ElmGiveEverstoneScript:
	writetext ElmGiveEverstoneText1
	promptbutton
	verbosegiveitem EVERSTONE
	iffalse ElmScript_NoRoomForEverstone
	writetext ElmGiveEverstoneText2
	waitbutton
	closetext
	setevent EVENT_GOT_EVERSTONE_FROM_ELM
	end

ElmScript_CallYou:
	writetext ElmText_CallYou
	waitbutton
ElmScript_NoRoomForEverstone:
	closetext
	end

ElmGiveMasterBallScript:
	writetext ElmGiveMasterBallText1
	promptbutton
	verbosegiveitem MASTER_BALL
	iffalse .notdone
	setevent EVENT_GOT_MASTER_BALL_FROM_ELM
	writetext ElmGiveMasterBallText2
	waitbutton
.notdone
	closetext
	end

ElmGiveTicketScript:
	writetext ElmGiveTicketText1
	promptbutton
	verbosegiveitem S_S_TICKET
	setevent EVENT_GOT_SS_TICKET_FROM_ELM
	writetext ElmGiveTicketText2
	waitbutton
	closetext
	end

ElmJumpBackScript1:
	closetext
	readvar VAR_FACING
	ifequal DOWN, ElmJumpDownScript
	ifequal UP, ElmJumpUpScript
	ifequal LEFT, ElmJumpLeftScript
	ifequal RIGHT, ElmJumpRightScript
	end

ElmJumpBackScript2:
	closetext
	readvar VAR_FACING
	ifequal DOWN, ElmJumpUpScript
	ifequal UP, ElmJumpDownScript
	ifequal LEFT, ElmJumpRightScript
	ifequal RIGHT, ElmJumpLeftScript
	end

ElmJumpUpScript:
	applymovement ELMSLAB_ELM, ElmJumpUpMovement
	opentext
	end

ElmJumpDownScript:
	applymovement ELMSLAB_ELM, ElmJumpDownMovement
	opentext
	end

ElmJumpLeftScript:
	applymovement ELMSLAB_ELM, ElmJumpLeftMovement
	opentext
	end

ElmJumpRightScript:
	applymovement ELMSLAB_ELM, ElmJumpRightMovement
	opentext
	end

AideScript_WalkPotion1:
	applymovement ELMSLAB_ELMS_AIDE, AideWalksRight1
	turnobject PLAYER, DOWN
	scall AideScript_GivePotion
	applymovement ELMSLAB_ELMS_AIDE, AideWalksLeft1
	end

AideScript_WalkPotion2:
	applymovement ELMSLAB_ELMS_AIDE, AideWalksRight2
	turnobject PLAYER, DOWN
	scall AideScript_GivePotion
	applymovement ELMSLAB_ELMS_AIDE, AideWalksLeft2
	end

AideScript_GivePotion:
	opentext
	writetext AideText_GiveYouPotion
	promptbutton
	verbosegiveitem POTION
	writetext AideText_AlwaysBusy
	waitbutton
	closetext
	setscene SCENE_ELMSLAB_NOOP
	end

AideScript_WalkBalls1:
	applymovement ELMSLAB_ELMS_AIDE, AideWalksRight1
	turnobject PLAYER, DOWN
	scall AideScript_GiveYouBalls
	applymovement ELMSLAB_ELMS_AIDE, AideWalksLeft1
	end

AideScript_WalkBalls2:
	applymovement ELMSLAB_ELMS_AIDE, AideWalksRight2
	turnobject PLAYER, DOWN
	scall AideScript_GiveYouBalls
	applymovement ELMSLAB_ELMS_AIDE, AideWalksLeft2
	end

AideScript_GiveYouBalls:
	opentext
	writetext AideText_GiveYouBalls
	promptbutton
	getitemname STRING_BUFFER_4, POKE_BALL
	scall AideScript_ReceiveTheBalls
	giveitem POKE_BALL, 5
	writetext AideText_ExplainBalls
	promptbutton
	itemnotify
	closetext
	setscene SCENE_ELMSLAB_NOOP
	end

AideScript_ReceiveTheBalls:
	jumpstd ReceiveItemScript
	end

ElmsAideScript:
	faceplayer
	opentext
	checkevent EVENT_GOT_TOGEPI_EGG_FROM_ELMS_AIDE
	iftrue AideScript_AfterTheft
	checkevent EVENT_GAVE_MYSTERY_EGG_TO_ELM
	iftrue AideScript_ExplainBalls
	checkevent EVENT_GOT_MYSTERY_EGG_FROM_MR_POKEMON
	iftrue AideScript_TheftTestimony
	writetext AideText_AlwaysBusy
	waitbutton
	closetext
	end

AideScript_TheftTestimony:
	writetext AideText_TheftTestimony
	waitbutton
	closetext
	end

AideScript_ExplainBalls:
	writetext AideText_ExplainBalls
	waitbutton
	closetext
	end

AideScript_AfterTheft:
	writetext AideText_AfterTheft
	waitbutton
	closetext
	end

MeetCopScript2:
	applymovement PLAYER, MeetCopScript2_StepLeft

MeetCopScript:
	applymovement PLAYER, MeetCopScript_WalkUp
CopScript:
	turnobject ELMSLAB_OFFICER, LEFT
	opentext
	writetext ElmsLabOfficerText1
	promptbutton
	special NameRival
	writetext ElmsLabOfficerText2
	waitbutton
	closetext
	applymovement ELMSLAB_OFFICER, OfficerLeavesMovement
	disappear ELMSLAB_OFFICER
	setscene SCENE_ELMSLAB_NOOP
	end

ElmsLabWindow:
	opentext
	checkflag ENGINE_FLYPOINT_VIOLET
	iftrue .Normal
	checkevent EVENT_ELM_CALLED_ABOUT_STOLEN_POKEMON
	iftrue .BreakIn
	sjump .Normal

.BreakIn:
	writetext ElmsLabWindowText2
	waitbutton
	closetext
	end

.Normal:
	writetext ElmsLabWindowText1
	waitbutton
	closetext
	end

ElmsLabTravelTip1:
	jumptext ElmsLabTravelTip1Text

ElmsLabTravelTip2:
	jumptext ElmsLabTravelTip2Text

ElmsLabTravelTip3:
	jumptext ElmsLabTravelTip3Text

ElmsLabTravelTip4:
	jumptext ElmsLabTravelTip4Text

ElmsLabTrashcan:
	jumptext ElmsLabTrashcanText

ElmsLabPC:
	jumptext ElmsLabPCText

ElmsLabTrashcan2: ; unreferenced
	jumpstd TrashCanScript

ElmsLabBookshelf:
	jumpstd DifficultBookshelfScript

ElmsLab_WalkUpToElmMovement:
	step UP
	step UP
	step UP
	step UP
	step UP
	step UP
	step UP
	turn_head LEFT
	step_end

ElmsLab_CantLeaveMovement:
	step UP
	step_end

MeetCopScript2_StepLeft:
	step LEFT
	step_end

MeetCopScript_WalkUp:
	step UP
	step UP
	turn_head RIGHT
	step_end

OfficerLeavesMovement:
	step DOWN
	step DOWN
	step DOWN
	step DOWN
	step DOWN
	step_end

AideWalksRight1:
	step RIGHT
	step RIGHT
	turn_head UP
	step_end

AideWalksRight2:
	step RIGHT
	step RIGHT
	step RIGHT
	turn_head UP
	step_end

AideWalksLeft1:
	step LEFT
	step LEFT
	turn_head DOWN
	step_end

AideWalksLeft2:
	step LEFT
	step LEFT
	step LEFT
	turn_head DOWN
	step_end

ElmJumpUpMovement:
	fix_facing
	big_step UP
	remove_fixed_facing
	step_end

ElmJumpDownMovement:
	fix_facing
	big_step DOWN
	remove_fixed_facing
	step_end

ElmJumpLeftMovement:
	fix_facing
	big_step LEFT
	remove_fixed_facing
	step_end

ElmJumpRightMovement:
	fix_facing
	big_step RIGHT
	remove_fixed_facing
	step_end

ElmsLab_ElmToDefaultPositionMovement1:
	step UP
	step_end

ElmsLab_ElmToDefaultPositionMovement2:
	step RIGHT
	step RIGHT
	step UP
	turn_head DOWN
	step_end

AfterBulbasaurMovement:
	step LEFT
	step UP
	turn_head UP
	step_end

AfterCharmanderMovement:
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterSquirtleMovement:
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterChikoritaMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterCyndaquilMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterTotodileMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterTreeckoMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterTorchicMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterMudkipMovement:
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterTurtwigMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterChimcharMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterPiplupMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterSnivyMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterTepigMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

AfterOshawottMovement:
	step UP
	step UP
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step LEFT
	step UP
	turn_head UP
	step_end

ElmText_Intro:
	text "Elm: <PLAY_G>!"
	line "There you are!"

	para "I needed to ask"
	line "you a favor."

	para "I'm conducting new"
	line "#mon research"

	para "right now. I was"
	line "wondering if you"

	para "could help me with"
	line "it, <PLAY_G>."

	para "You see…"

	para "I'm writing a"
	line "paper that I want"

	para "to present at a"
	line "conference."

	para "But there are some"
	line "things I don't"

	para "quite understand"
	line "yet."

	para "So!"

	para "I'd like you to"
	line "raise a #mon"

	para "that I recently"
	line "caught."
	done

ElmText_Accepted:
	text "Thanks, <PLAY_G>!"

	para "You're a great"
	line "help!"
	done

ElmText_Refused:
	text "But… Please, I"
	line "need your help!"
	done

ElmText_ResearchAmbitions:
	text "When I announce my"
	line "findings, I'm sure"

	para "we'll delve a bit"
	line "deeper into the"

	para "many mysteries of"
	line "#mon."

	para "You can count on"
	line "it!"
	done

ElmText_GotAnEmail:
	text "Oh, hey! I got an"
	line "e-mail!"

	para "<……><……><……>"
	line "Hm… Uh-huh…"

	para "Okay…"
	done

ElmText_MissionFromMrPokemon:
	text "Hey, listen."

	para "I have an acquain-"
	line "tance called Mr."
	cont "#mon."

	para "He keeps finding"
	line "weird things and"

	para "raving about his"
	line "discoveries."

	para "Anyway, I just got"
	line "an e-mail from him"

	para "saying that this"
	line "time it's real."

	para "It is intriguing,"
	line "but we're busy"

	para "with our #mon"
	line "research…"

	para "Wait!"

	para "I know!"

	para "<PLAY_G>, can you"
	line "go in our place?"
	done

ElmText_ChooseAPokemon:
	text "I want you to"
	line "raise one of the"

	para "#mon contained"
	line "in these Balls."

	para "You'll be that"
	line "#mon's first"
	cont "partner, <PLAY_G>!"

	para "Go on. Pick one!"
	done

ElmText_LetYourMonBattleIt:
	text "If a wild #mon"
	line "appears, let your"
	cont "#mon battle it!"
	done

LabWhereGoingText:
	text "Elm: Wait! Where"
	line "are you going?"
	done

TakeGrassStarterText:
	text "Elm: So, you like"
	line "@"
	text_ram wStringBuffer3
	text ", the"
	cont "grass #mon?"
	done

TakeFireStarterText:
	text "Elm: You'll take"
	line "@"
	text_ram wStringBuffer3
	text ", the"
	cont "fire #mon?"
	done

TakeWaterStarterText:
	text "Elm: Do you want"
	line "@"
	text_ram wStringBuffer3
	text ", the"
	cont "water #mon?"
	done

DidntChooseStarterText:
	text "Elm: Think it over"
	line "carefully."

	para "Your partner is"
	line "important."
	done

ChoseStarterText:
	text "Elm: I think"
	line "that's a great"
	cont "#mon too!"
	done

ReceivedStarterText:
	text "<PLAYER> received"
	line "@"
	text_ram wStringBuffer3
	text "!"
	done

ElmDirectionsText1:
	text "Mr.#mon lives a"
	line "little bit beyond"

	para "Cherrygrove, the"
	line "next city over."

	para "It's almost a"
	line "direct route"

	para "there, so you"
	line "can't miss it."

	para "But just in case,"
	line "here's my phone"

	para "number. Call me if"
	line "anything comes up!"
	done

ElmDirectionsText2:
	text "If your #mon is"
	line "hurt, you should"

	para "heal it with this"
	line "machine."

	para "Feel free to use"
	line "it anytime."
	done

ElmDirectionsText3:
	text "<PLAY_G>, I'm"
	line "counting on you!"
	done

GotElmsNumberText:
	text "<PLAYER> got Elm's"
	line "phone number."
	done

ElmDescribesMrPokemonText:
	text "Mr.#mon goes"
	line "everywhere and"
	cont "finds rarities."

	para "Too bad they're"
	line "just rare and"
	cont "not very useful…"
	done

ElmsLabTakeBonusStarterText:
	text "Elm: You beat RED?"
	line "Amazing!"

	para "Will you take"
	line "@"
	text_ram wStringBuffer3
	text " too?"
	done

ElmsLabBonusStarterNoText:
	text "Elm: Take your"
	line "time choosing."
	done

ElmsLabBonusStarterNoRoomText:
	text "Elm: Your party"
	line "and your PC box"
	cont "are both full!"
	done

ElmPokeBallText:
	text "It contains a"
	line "#mon caught by"
	cont "Prof.Elm."
	done

ElmsLabHealingMachineText1:
	text "I wonder what this"
	line "does?"
	done

ElmsLabHealingMachineText2:
	text "Would you like to"
	line "heal your #mon?"
	done

ElmAfterTheftText1:
	text "Elm: <PLAY_G>, it"
	line "was awful…"

	para "A boy with red"
	line "hair barged in,"

	para "called all my"
	line "#mon trash and"
	cont "wrecked the Lab!"

	para "…Oh, yes, what was"
	line "Mr.#mon's big"
	cont "discovery?"
	done

ElmAfterTheftText2:
	text "<PLAYER> handed"
	line "the Mystery Egg to"
	cont "Prof.Elm."
	done

ElmAfterTheftText3:
	text "Elm: This?"
	done

ElmAfterTheftText4:
	text "But… Is it a"
	line "#mon Egg?"

	para "If it is, it is a"
	line "great discovery!"
	done

ElmAfterTheftText5:
	text "Elm: What?!?"

	para "Prof.Oak gave you"
	line "a #dex?"

	para "<PLAY_G>, is that"
	line "true? Th-that's"
	cont "incredible!"

	para "He is superb at"
	line "seeing the poten-"
	cont "tial of people as"
	cont "trainers."

	para "Wow, <PLAY_G>. You"
	line "may have what it"

	para "takes to become"
	line "the Champion."

	para "You seem to be"
	line "getting on great"
	cont "with #mon too."

	para "You should take"
	line "the #mon Gym"
	cont "challenge."

	para "The closest Gym"
	line "would be the one"
	cont "in Violet City."
	done

ElmAfterTheftText6:
	text "…<PLAY_G>. The"
	line "road to the"

	para "championship will"
	line "be a long one."

	para "Before you leave,"
	line "make sure that you"
	cont "talk to your mom."
	done

ElmStudyingEggText:
	text "Elm: Don't give"
	line "up! I'll call if"

	para "I learn anything"
	line "about that Egg!"
	done

ElmAideHasEggText:
	text "Elm: <PLAY_G>?"
	line "Didn't you meet my"
	cont "assistant?"

	para "He should have met"
	line "you with the Egg"

	para "at Violet City's"
	line "#mon Center."

	para "You must have just"
	line "missed him. Try to"
	cont "catch him there."
	done

ElmWaitingEggHatchText:
	text "Elm: Hey, has that"
	line "Egg changed any?"
	done

ElmThoughtEggHatchedText:
	text "<PLAY_G>? I thought"
	line "the Egg hatched."

	para "Where is the"
	line "#mon?"
	done

ShowElmTogepiText1:
	text "Elm: <PLAY_G>, you"
	line "look great!"
	done

ShowElmTogepiText2:
	text "What?"
	line "That #mon!?!"
	done

ShowElmTogepiText3:
	text "The Egg hatched!"
	line "So, #mon are"
	cont "born from Eggs…"

	para "No, perhaps not"
	line "all #mon are."

	para "Wow, there's still"
	line "a lot of research"
	cont "to be done."
	done

ElmGiveEverstoneText1:
	text "Thanks, <PLAY_G>!"
	line "You're helping"

	para "unravel #mon"
	line "mysteries for us!"

	para "I want you to have"
	line "this as a token of"
	cont "our appreciation."
	done

ElmGiveEverstoneText2:
	text "That's an"
	line "Everstone."

	para "Some species of"
	line "#mon evolve"

	para "when they grow to"
	line "certain levels."

	para "A #mon holding"
	line "the Everstone"
	cont "won't evolve."

	para "Give it to a #-"
	line "Mon you don't want"
	cont "to evolve."
	done

ElmText_CallYou:
	text "Elm: <PLAY_G>, I'll"
	line "call you if any-"
	cont "thing comes up."
	done

AideText_AfterTheft:
	text "That boy who"
	line "trashed the Lab…"

	para "I heard his dad"
	line "just bought him"
	cont "some rare dragon."

	para "Some people get"
	line "everything handed"
	cont "to them."
	done

ElmGiveMasterBallText1:
	text "Elm: Hi, <PLAY_G>!"
	line "Thanks to you, my"

	para "research is going"
	line "great!"

	para "Take this as a"
	line "token of my"
	cont "appreciation."
	done

ElmGiveMasterBallText2:
	text "The Master Ball is"
	line "the best!"

	para "It's the ultimate"
	line "Ball! It'll catch"

	para "any #mon with-"
	line "out fail."

	para "It's given only to"
	line "recognized #mon"
	cont "researchers."

	para "I think you can"
	line "make much better"

	para "use of it than I"
	line "can, <PLAY_G>!"
	done

ElmGiveTicketText1:
	text "Elm: <PLAY_G>!"
	line "There you are!"

	para "I called because I"
	line "have something for"
	cont "you."

	para "See? It's an"
	line "S.S.Ticket."

	para "Now you can catch"
	line "#mon in Kanto."
	done

ElmGiveTicketText2:
	text "The ship departs"
	line "from Olivine City."

	para "But you knew that"
	line "already, <PLAY_G>."

	para "After all, you've"
	line "traveled all over"
	cont "with your #mon."

	para "Give my regards to"
	line "Prof.Oak in Kanto!"
	done

ElmsLabMonEggText: ; unreferenced
	text "It's the #mon"
	line "Egg being studied"
	cont "by Prof.Elm."
	done

AideText_GiveYouPotion:
	text "<PLAY_G>, I want"
	line "you to have this"
	cont "for your errand."
	done

AideText_AlwaysBusy:
	text "There are only two"
	line "of us, so we're"
	cont "always busy."
	done

AideText_TheftTestimony:
	text "A red-haired boy"
	line "came in and looked"
	cont "at every #mon."

	para "Then he said none"
	line "were good enough"
	cont "for him!"

	para "He threw a fit,"
	line "trashed the place"
	cont "and stormed out."

	para "Who raises a kid"
	line "like that?"
	done

AideText_GiveYouBalls:
	text "<PLAY_G>!"

	para "Use these on your"
	line "#dex quest!"
	done

AideText_ExplainBalls:
	text "To add to your"
	line "#dex, you have"
	cont "to catch #mon."

	para "Throw # Balls"
	line "at wild #mon"
	cont "to get them."
	done

ElmsLabOfficerText1:
	text "I heard about some"
	line "vandalism here…"

	para "I was just getting"
	line "some information"
	cont "from Prof.Elm."

	para "Apparently, it was"
	line "a young male with"
	cont "long, red hair…"

	para "What?"

	para "You battled a"
	line "trainer like that?"

	para "Did you happen to"
	line "get his name?"
	done

ElmsLabOfficerText2:
	text "OK! So <RIVAL>"
	line "was his name."

	para "Wait… <RIVAL>?"

	para "Oh no. His father"
	line "has connections…"

	para "I, uh, may have to"
	line "drop this case."
	done

ElmsLabWindowText1:
	text "The window's open."

	para "A pleasant breeze"
	line "is blowing in."
	done

ElmsLabWindowText2:
	text "The glass is"
	line "smashed. He kicked"
	cont "it on his way out!"
	done

ElmsLabTravelTip1Text:
	text "<PLAYER> opened a"
	line "book."

	para "Travel Tip 1:"

	para "Press Start to"
	line "open the Menu."
	done

ElmsLabTravelTip2Text:
	text "<PLAYER> opened a"
	line "book."

	para "Travel Tip 2:"

	para "Record your trip"
	line "with Save!"
	done

ElmsLabTravelTip3Text:
	text "<PLAYER> opened a"
	line "book."

	para "Travel Tip 3:"

	para "Open your Pack and"
	line "press Select to"
	cont "move items."
	done

ElmsLabTravelTip4Text:
	text "<PLAYER> opened a"
	line "book."

	para "Travel Tip 4:"

	para "Check your #mon"
	line "moves. Press the"

	para "A Button to switch"
	line "moves."
	done

ElmsLabTrashcanText:
	text "The wrapper from"
	line "the snack Prof.Elm"
	cont "ate is in there…"
	done

ElmsLabPCText:
	text "Observations on"
	line "#mon Evolution"

	para "…It says on the"
	line "screen…"
	done

ElmsLab_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  4, 11, NEW_BARK_TOWN, 1
	warp_event  5, 11, NEW_BARK_TOWN, 1

	def_coord_events
	coord_event  4,  6, SCENE_ELMSLAB_CANT_LEAVE, LabTryToLeaveScript
	coord_event  5,  6, SCENE_ELMSLAB_CANT_LEAVE, LabTryToLeaveScript
	coord_event  4,  5, SCENE_ELMSLAB_MEET_OFFICER, MeetCopScript
	coord_event  5,  5, SCENE_ELMSLAB_MEET_OFFICER, MeetCopScript2
	coord_event  4,  8, SCENE_ELMSLAB_AIDE_GIVES_POTION, AideScript_WalkPotion1
	coord_event  5,  8, SCENE_ELMSLAB_AIDE_GIVES_POTION, AideScript_WalkPotion2
	coord_event  4,  8, SCENE_ELMSLAB_AIDE_GIVES_POKE_BALLS, AideScript_WalkBalls1
	coord_event  5,  8, SCENE_ELMSLAB_AIDE_GIVES_POKE_BALLS, AideScript_WalkBalls2

	def_bg_events
	bg_event  2,  1, BGEVENT_READ, ElmsLabHealingMachine
	bg_event  6,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event  7,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event  8,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event  9,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event  0,  7, BGEVENT_READ, ElmsLabTravelTip1
	bg_event  1,  7, BGEVENT_READ, ElmsLabTravelTip2
	bg_event  2,  7, BGEVENT_READ, ElmsLabTravelTip3
	bg_event  3,  7, BGEVENT_READ, ElmsLabTravelTip4
	bg_event  6,  7, BGEVENT_READ, ElmsLabBookshelf
	bg_event  7,  7, BGEVENT_READ, ElmsLabBookshelf
	bg_event  8,  7, BGEVENT_READ, ElmsLabBookshelf
	bg_event  9,  7, BGEVENT_READ, ElmsLabBookshelf
	bg_event  9,  3, BGEVENT_READ, ElmsLabTrashcan
	bg_event  5,  0, BGEVENT_READ, ElmsLabWindow
	bg_event  3,  5, BGEVENT_DOWN, ElmsLabPC
	bg_event  6,  3, BGEVENT_UP, BulbasaurPokeBallScript
	bg_event  7,  3, BGEVENT_UP, CharmanderPokeBallScript
	bg_event  8,  3, BGEVENT_UP, SquirtlePokeBallScript
	bg_event 10,  3, BGEVENT_UP, ChikoritaPokeBallScript
	bg_event 11,  3, BGEVENT_UP, CyndaquilPokeBallScript
	bg_event 12,  3, BGEVENT_UP, TotodilePokeBallScript
	bg_event 14,  3, BGEVENT_UP, TreeckoPokeBallScript
	bg_event 15,  3, BGEVENT_UP, TorchicPokeBallScript
	bg_event 16,  3, BGEVENT_UP, MudkipPokeBallScript
	bg_event 10,  7, BGEVENT_DOWN, TurtwigPokeBallScript
	bg_event 11,  7, BGEVENT_DOWN, ChimcharPokeBallScript
	bg_event 12,  7, BGEVENT_DOWN, PiplupPokeBallScript
	bg_event 14,  7, BGEVENT_DOWN, SnivyPokeBallScript
	bg_event 15,  7, BGEVENT_DOWN, TepigPokeBallScript
	bg_event 16,  7, BGEVENT_DOWN, OshawottPokeBallScript
	bg_event 13,  3, BGEVENT_READ, ElmsLabTrashcan
	bg_event 17,  3, BGEVENT_READ, ElmsLabTrashcan
	bg_event 13,  7, BGEVENT_READ, ElmsLabTrashcan
	bg_event 17,  7, BGEVENT_READ, ElmsLabTrashcan
	bg_event 10,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 11,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 12,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 13,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 14,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 15,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 16,  1, BGEVENT_READ, ElmsLabBookshelf
	bg_event 17,  1, BGEVENT_READ, ElmsLabBookshelf

	def_object_events
	object_event  5,  2, SPRITE_ELM, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, ProfElmScript, -1
	object_event  2,  9, SPRITE_SCIENTIST, SPRITEMOVEDATA_SPINRANDOM_SLOW, 0, 0, -1, -1, PAL_NPC_BLUE, OBJECTTYPE_SCRIPT, 0, ElmsAideScript, EVENT_ELMS_AIDE_IN_LAB
	object_event  5,  3, SPRITE_OFFICER, SPRITEMOVEDATA_STANDING_UP, 0, 0, -1, -1, PAL_NPC_BLUE, OBJECTTYPE_SCRIPT, 0, CopScript, EVENT_COP_IN_ELMS_LAB
