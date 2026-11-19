Marts:
; entries correspond to MART_* constants (see constants/mart_constants.asm)
	table_width 2
	dw MartCherrygrove
	dw MartCherrygroveDex
	dw MartViolet
	dw MartAzalea
	dw MartCianwood
	dw MartGoldenrod2F1
	dw MartGoldenrod2F2
	dw MartGoldenrod3F
	dw MartGoldenrod4F
	dw MartGoldenrod5FSunday
	dw MartGoldenrod5FMonday
	dw MartGoldenrod5FTuesday
	dw MartGoldenrod5FWednesday
	dw MartGoldenrod5FThursday
	dw MartGoldenrod5FFriday
	dw MartGoldenrod5FSaturday
	dw MartOlivine
	dw MartEcruteak
	dw MartMahogany1
	dw MartMahogany2
	dw MartBlackthorn
	dw MartViridian
	dw MartPewter
	dw MartCerulean
	dw MartLavender
	dw MartVermilion
	dw MartCeladon2F1
	dw MartCeladon2F2
	dw MartCeladon3F
	dw MartCeladon4F
	dw MartCeladon5F1
	dw MartCeladon5F2
	dw MartFuchsia
	dw MartSaffron
	dw MartMtMoon
	dw MartIndigoPlateau
	dw MartUnderground
	assert_table_length NUM_MARTS

MartCherrygrove:
	db 6 ; # items
	db POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	; local TMs: first steps
	db TM_ROLLOUT
	db TM_DEFENSE_CURL
	db -1 ; end

MartCherrygroveDex:
	db 7 ; # items
	db POKE_BALL
	db POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	; local TMs: first steps
	db TM_ROLLOUT
	db TM_DEFENSE_CURL
	db -1 ; end

MartViolet:
	db 12 ; # items
	db POKE_BALL
	db POTION
	db ESCAPE_ROPE
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db X_DEFEND
	db X_ATTACK
	db X_SPEED
	db FLOWER_MAIL
	; local TMs: birds
	db TM_STEEL_WING
	db TM_SWIFT
	db -1 ; end

MartAzalea:
	db 12 ; # items
	db CHARCOAL
	db POKE_BALL
	db POTION
	db SUPER_POTION
	db ESCAPE_ROPE
	db REPEL
	db ANTIDOTE
	db PARLYZ_HEAL
	db FLOWER_MAIL
	; local TMs: bugs and Slowpoke
	db TM_FURY_CUTTER
	db TM_SWEET_SCENT
	db TM_HEADBUTT
	db -1 ; end

MartCianwood:
	db 8 ; # items
	db POTION
	db SUPER_POTION
	db HYPER_POTION
	db FULL_HEAL
	db REVIVE
	; local TMs: fighting
	db TM_DYNAMICPUNCH
	db TM_DETECT
	db TM_ROCK_SMASH
	db -1 ; end

MartGoldenrod2F1:
	db 7 ; # items
	db POTION
	db SUPER_POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	db ICE_HEAL
	db -1 ; end

MartGoldenrod2F2:
	db 8 ; # items
	db POKE_BALL
	db GREAT_BALL
	db ESCAPE_ROPE
	db REPEL
	db REVIVE
	db FULL_HEAL
	db POKE_DOLL
	db FLOWER_MAIL
	db -1 ; end

MartGoldenrod3F:
	db 7 ; # items
	db X_SPEED
	db X_SPECIAL
	db X_DEFEND
	db X_ATTACK
	db DIRE_HIT
	db GUARD_SPEC
	db X_ACCURACY
	db -1 ; end

MartGoldenrod4F:
	db 5 ; # items
	db PROTEIN
	db IRON
	db CARBOS
	db CALCIUM
	db HP_UP
	db -1 ; end

MartGoldenrod5FSunday: ; daily special: ghosts and minds
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_SHADOW_BALL
	db TM_PSYCHIC_M
	db TM_DREAM_EATER
	db TM_NIGHTMARE
	db TM_CURSE
	db TM_PSYCH_UP
	db TM_SWAGGER
	db TM_ATTRACT
	db TM_DOUBLE_TEAM
	db -1 ; end

MartGoldenrod5FMonday: ; daily special: grass and poison
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_GIGA_DRAIN
	db TM_SOLARBEAM
	db TM_SUNNY_DAY
	db TM_SWEET_SCENT
	db TM_SLUDGE_BOMB
	db TM_TOXIC
	db TM_MUD_SLAP
	db TM_DIG
	db TM_FURY_CUTTER
	db -1 ; end

MartGoldenrod5FTuesday: ; daily special: electric and steel
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_THUNDER
	db TM_ZAP_CANNON
	db TM_RAIN_DANCE
	db TM_SWIFT
	db TM_IRON_TAIL
	db TM_STEEL_WING
	db TM_PROTECT
	db TM_DETECT
	db TM_ENDURE
	db -1 ; end

MartGoldenrod5FWednesday: ; daily special: ice and ground
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_BLIZZARD
	db TM_ICY_WIND
	db TM_EARTHQUAKE
	db TM_SANDSTORM
	db TM_ROLLOUT
	db TM_DEFENSE_CURL
	db TM_REST
	db TM_SLEEP_TALK
	db TM_SNORE
	db -1 ; end

MartGoldenrod5FThursday: ; daily special: fire and dragon
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_FIRE_BLAST
	db TM_DRAGONBREATH
	db TM_SUNNY_DAY
	db TM_ROAR
	db TM_RETURN
	db TM_FRUSTRATION
	db TM_HIDDEN_POWER
	db TM_THIEF
	db TM_ENDURE
	db -1 ; end

MartGoldenrod5FFriday: ; daily special: fighting
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_DYNAMICPUNCH
	db TM_IRON_TAIL
	db TM_DIG
	db TM_DETECT
	db TM_SWAGGER
	db TM_PSYCH_UP
	db TM_REST
	db TM_SLEEP_TALK
	db TM_PROTECT
	db -1 ; end

MartGoldenrod5FSaturday: ; daily special: jackpot: the big hitters
	db 14 ; # items
	db TM_THUNDERPUNCH
	db TM_FIRE_PUNCH
	db TM_ICE_PUNCH
	db TM_HEADBUTT
	db TM_ROCK_SMASH
	db TM_EARTHQUAKE
	db TM_PSYCHIC_M
	db TM_THUNDER
	db TM_BLIZZARD
	db TM_FIRE_BLAST
	db TM_SHADOW_BALL
	db TM_HYPER_BEAM
	db TM_RETURN
	db TM_TOXIC
	db -1 ; end

MartOlivine:
	db 12 ; # items
	db GREAT_BALL
	db SUPER_POTION
	db HYPER_POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db ICE_HEAL
	db SUPER_REPEL
	db SURF_MAIL
	; local TMs: steel and sea
	db TM_IRON_TAIL
	db TM_STEEL_WING
	db TM_RAIN_DANCE
	db -1 ; end

MartEcruteak:
	db 13 ; # items
	db POKE_BALL
	db GREAT_BALL
	db POTION
	db SUPER_POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	db ICE_HEAL
	db REVIVE
	; local TMs: ghosts
	db TM_SHADOW_BALL
	db TM_NIGHTMARE
	db TM_DREAM_EATER
	db -1 ; end

MartMahogany1:
	db 6 ; # items
	db TINYMUSHROOM
	db SLOWPOKETAIL
	db POKE_BALL
	db POTION
	; local TMs: Team Rocket's
	db TM_THIEF
	db TM_TOXIC
	db -1 ; end

MartMahogany2:
	db 11 ; # items
	db RAGECANDYBAR
	db GREAT_BALL
	db SUPER_POTION
	db HYPER_POTION
	db ANTIDOTE
	db PARLYZ_HEAL
	db SUPER_REPEL
	db REVIVE
	db FLOWER_MAIL
	; local TMs: ice
	db TM_ICY_WIND
	db TM_BLIZZARD
	db -1 ; end

MartBlackthorn:
	db 11 ; # items
	db GREAT_BALL
	db ULTRA_BALL
	db HYPER_POTION
	db MAX_POTION
	db FULL_HEAL
	db REVIVE
	db MAX_REPEL
	db X_DEFEND
	db X_ATTACK
	; local TMs: dragons
	db TM_DRAGONBREATH
	db TM_HYPER_BEAM
	db -1 ; end

MartViridian:
	db 11 ; # items
	db ULTRA_BALL
	db HYPER_POTION
	db FULL_HEAL
	db REVIVE
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	db FLOWER_MAIL
	; local TMs: ground
	db TM_EARTHQUAKE
	db TM_DIG
	db -1 ; end

MartPewter:
	db 10 ; # items
	db GREAT_BALL
	db SUPER_POTION
	db SUPER_REPEL
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	; local TMs: rock
	db TM_SANDSTORM
	db TM_ROCK_SMASH
	db TM_ROLLOUT
	db -1 ; end

MartCerulean:
	db 11 ; # items
	db GREAT_BALL
	db ULTRA_BALL
	db SUPER_POTION
	db SUPER_REPEL
	db FULL_HEAL
	db X_DEFEND
	db X_ATTACK
	db DIRE_HIT
	db SURF_MAIL
	; local TMs: water
	db TM_RAIN_DANCE
	db TM_ATTRACT
	db -1 ; end

MartLavender:
	db 11 ; # items
	db GREAT_BALL
	db POTION
	db SUPER_POTION
	db MAX_REPEL
	db ANTIDOTE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	; local TMs: ghosts
	db TM_CURSE
	db TM_NIGHTMARE
	db TM_SHADOW_BALL
	db -1 ; end

MartVermilion:
	db 11 ; # items
	db ULTRA_BALL
	db SUPER_POTION
	db HYPER_POTION
	db REVIVE
	db PARLYZ_HEAL
	db AWAKENING
	db BURN_HEAL
	db LITEBLUEMAIL
	; local TMs: electric
	db TM_THUNDER
	db TM_ZAP_CANNON
	db TM_THUNDERPUNCH
	db -1 ; end

MartCeladon2F1:
	db 7 ; # items
	db POTION
	db SUPER_POTION
	db HYPER_POTION
	db MAX_POTION
	db REVIVE
	db SUPER_REPEL
	db MAX_REPEL
	db -1 ; end

MartCeladon2F2:
	db 10 ; # items
	db POKE_BALL
	db GREAT_BALL
	db ULTRA_BALL
	db ESCAPE_ROPE
	db FULL_HEAL
	db ANTIDOTE
	db BURN_HEAL
	db ICE_HEAL
	db AWAKENING
	db PARLYZ_HEAL
	db -1 ; end

MartCeladon3F: ; post-game power TMs
	db 14 ; # items
	db TM_HYPER_BEAM
	db TM_EARTHQUAKE
	db TM_PSYCHIC_M
	db TM_THUNDER
	db TM_BLIZZARD
	db TM_FIRE_BLAST
	db TM_SHADOW_BALL
	db TM_SLUDGE_BOMB
	db TM_GIGA_DRAIN
	db TM_IRON_TAIL
	db TM_DYNAMICPUNCH
	db TM_DRAGONBREATH
	db TM_RETURN
	db TM_TOXIC
	db -1 ; end

MartCeladon4F:
	db 3 ; # items
	db POKE_DOLL
	db LOVELY_MAIL
	db SURF_MAIL
	db -1 ; end

MartCeladon5F1:
	db 5 ; # items
	db HP_UP
	db PROTEIN
	db IRON
	db CARBOS
	db CALCIUM
	db -1 ; end

MartCeladon5F2:
	db 7 ; # items
	db X_ACCURACY
	db GUARD_SPEC
	db DIRE_HIT
	db X_ATTACK
	db X_DEFEND
	db X_SPEED
	db X_SPECIAL
	db -1 ; end

MartFuchsia:
	db 10 ; # items
	db GREAT_BALL
	db ULTRA_BALL
	db SUPER_POTION
	db HYPER_POTION
	db FULL_HEAL
	db MAX_REPEL
	db FLOWER_MAIL
	; local TMs: poison
	db TM_TOXIC
	db TM_SLUDGE_BOMB
	db TM_SWAGGER
	db -1 ; end

MartSaffron:
	db 11 ; # items
	db GREAT_BALL
	db ULTRA_BALL
	db HYPER_POTION
	db MAX_POTION
	db FULL_HEAL
	db X_ATTACK
	db X_DEFEND
	db FLOWER_MAIL
	; local TMs: psychic
	db TM_PSYCHIC_M
	db TM_PSYCH_UP
	db TM_DREAM_EATER
	db -1 ; end

MartMtMoon:
	db 8 ; # items
	db POKE_DOLL
	db FRESH_WATER
	db SODA_POP
	db LEMONADE
	db REPEL
	db PORTRAITMAIL
	; local TMs: Clefairy
	db TM_DEFENSE_CURL
	db TM_REST
	db -1 ; end

MartIndigoPlateau:
	db 10 ; # items
	db ULTRA_BALL
	db MAX_REPEL
	db HYPER_POTION
	db MAX_POTION
	db FULL_RESTORE
	db REVIVE
	db FULL_HEAL
	; local TMs: champions
	db TM_HYPER_BEAM
	db TM_EARTHQUAKE
	db TM_RETURN
	db -1 ; end

MartUnderground:
	db 6 ; # items
	db ENERGYPOWDER
	db ENERGY_ROOT
	db HEAL_POWDER
	db REVIVAL_HERB
	; local TMs: shady
	db TM_FRUSTRATION
	db TM_THIEF
	db -1 ; end

DefaultMart:
	db 2 ; # items
	db POKE_BALL
	db POTION
	db -1 ; end
