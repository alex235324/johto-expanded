; Build flags for optional quality-of-life features.
; Each defaults to 1 (on). Turn one off at build time with, e.g.:
;   make tidy && make QOL_FLAGS="-DQOL_REPEL_PROMPT=0"
; (`make tidy` is needed because changing flags doesn't trigger a rebuild.)

MACRO qol_flag
	IF !DEF(\1)
		DEF \1 EQU \2
	ENDC
ENDM

	qol_flag QOL_REPEL_PROMPT, 1 ; ask to use another Repel when one wears off
	qol_flag QOL_FAST_POKECENTER, 1 ; shorter Nurse dialogue, no bowing pauses, faster heal machine
	qol_flag QOL_FAST_SAVE, 1 ; don't wait for the save jingle to end
	qol_flag QOL_REUSABLE_TMS, 1 ; TMs aren't used up; marts sell one of each TM you don't have
	qol_flag QOL_POISON_SURVIVE, 1 ; field poison stops at 1 HP and is cured instead of fainting
	qol_flag QOL_SOLO_TRADE_EVOS, 1 ; trade evolutions also happen on level-up (holding the item, if one is needed)
	qol_flag QOL_SOLO_TRADE_EVO_LEVEL, 37 ; level for trade evolutions that need no item
	qol_flag QOL_RESPAWN_LEGENDARIES, 1 ; uncaught Lugia, Ho-Oh, Raikou and Entei come back after each Elite Four win
	qol_flag QOL_ROAMING_SUICUNE, 1 ; Suicune flees from Tin Tower 1F and roams Johto instead of battling there
	qol_flag QOL_LEGENDARY_LOCATOR, 1 ; Pokémon Center 2F NPC who says where roaming legendaries are
	qol_flag QOL_MODERN_MOVES, 1 ; Gen 8 power/accuracy/PP for moves later generations changed (data/moves/modern_moves.asm)
	qol_flag QOL_EXP_SHARE_ALL, 1 ; whole party gains Exp. (non-battlers get half); using the Exp.Share item toggles it
DEF EXP_SHARE_ALL_NO_SPLIT EQU 2 ; wGivingExperienceToExpShareHolders value for the rest-of-team pass
	qol_flag QOL_CENTER_MOVE_DELETER, 1 ; the Pokémon Center 2F Move Reminder can also delete moves
	qol_flag QOL_BAG_SORT, 1 ; START sorts the Items, Balls or Key Items pocket
	qol_flag QOL_BIGGER_BAG, 1 ; Items 30, Balls 16, Key Items 30 (breaks older saves)
	qol_flag BLISSEY_EVERY_THIRD_ROUTE, 1 ; grass on Routes 3, 6, 9 ... 45 can give a Blissey
	qol_flag BLISSEY_ROUTE_PERCENT, 5 ; chance per grass encounter on those routes, in percent
	qol_flag QOL_MART_MAX_AFFORDABLE, 1 ; the most you can pick when buying is what you can afford, not 99
	qol_flag QOL_SHIFT_DEFAULT_NO, 1 ; Shift mode's "Will <PLAYER> change Pokémon?" starts on No
	qol_flag QOL_NURSE_TURN_AWAY, 1 ; after healing, the player turns away from the Nurse so mashing A doesn't talk to her again
	qol_flag QOL_MORE_BOXES, 1 ; 24 PC boxes instead of 14 (64 KB SRAM; breaks older saves)
	qol_flag QOL_FEWER_PHONE_CALLS, 1 ; 25% call chance and longer gaps between calls (60/40/30/20 min)
	qol_flag QOL_PHONE_REMATCH_MARKS, 1 ; "!" in the Pokégear phone list for trainers ready to battle or with a gift
