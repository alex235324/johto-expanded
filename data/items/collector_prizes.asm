; Collector Token prizes: item, price (prices must fit in a byte).
; Each category list holds 1-based indexes into CollectorPrizes.

CollectorPrizes:
	; HeldItems
	db LEFTOVERS,     15
	db LUCKY_EGG,     15
	db KINGS_ROCK,    10
	db SCOPE_LENS,    10
	db FOCUS_BAND,    10
	db BRIGHTPOWDER,  10
	db QUICK_CLAW,     8
	db AMULET_COIN,   10
	db EXP_SHARE,     10
	db MIRACLEBERRY,   2
	db GOLD_BERRY,     2
	db LIGHT_BALL,     8
	db THICK_CLUB,     8
	db METAL_POWDER,   5
	db LUCKY_PUNCH,    5
	db CHARCOAL,       5
	db MYSTIC_WATER,   5
	db MAGNET,         5
	db MIRACLE_SEED,   5
	db NEVERMELTICE,   5
	db BLACKBELT_I,    5
	db SHARP_BEAK,     5
	db POISON_BARB,    5
	db SOFT_SAND,      5
	db HARD_STONE,     5
	db SILVERPOWDER,   5
	db SPELL_TAG,      5
	db TWISTEDSPOON,   5
	db BLACKGLASSES,   5
	db DRAGON_FANG,    5
	db METAL_COAT,     5
	db PINK_BOW,       5
	; Training
	db RARE_CANDY,    10
	db PP_UP,          8
	db HP_UP,          8
	db PROTEIN,        8
	db IRON,           8
	db CARBOS,         8
	db CALCIUM,        8
	db MAX_REVIVE,     2
	db MAX_ELIXER,     2
	; Special
	db MASTER_BALL,   40
	db FIRE_STONE,     3
	db WATER_STONE,    3
	db THUNDERSTONE,   3
	db LEAF_STONE,     3
	db MOON_STONE,     3
	db SUN_STONE,      3
	db UP_GRADE,       5
	db DRAGON_SCALE,   5
CollectorPrizesEnd: ; CollectorCapSellPrice scans up to here

CollectorHeldItemsList:
	db 32
	db  1 ; LEFTOVERS
	db  2 ; LUCKY_EGG
	db  3 ; KINGS_ROCK
	db  4 ; SCOPE_LENS
	db  5 ; FOCUS_BAND
	db  6 ; BRIGHTPOWDER
	db  7 ; QUICK_CLAW
	db  8 ; AMULET_COIN
	db  9 ; EXP_SHARE
	db 10 ; MIRACLEBERRY
	db 11 ; GOLD_BERRY
	db 12 ; LIGHT_BALL
	db 13 ; THICK_CLUB
	db 14 ; METAL_POWDER
	db 15 ; LUCKY_PUNCH
	db 16 ; CHARCOAL
	db 17 ; MYSTIC_WATER
	db 18 ; MAGNET
	db 19 ; MIRACLE_SEED
	db 20 ; NEVERMELTICE
	db 21 ; BLACKBELT_I
	db 22 ; SHARP_BEAK
	db 23 ; POISON_BARB
	db 24 ; SOFT_SAND
	db 25 ; HARD_STONE
	db 26 ; SILVERPOWDER
	db 27 ; SPELL_TAG
	db 28 ; TWISTEDSPOON
	db 29 ; BLACKGLASSES
	db 30 ; DRAGON_FANG
	db 31 ; METAL_COAT
	db 32 ; PINK_BOW
	db -1

; Rare Candy only shows up once the Elite Four is beaten (CollectorShop).
CollectorTrainingList:
	db 8
	db 34 ; PP_UP
	db 35 ; HP_UP
	db 36 ; PROTEIN
	db 37 ; IRON
	db 38 ; CARBOS
	db 39 ; CALCIUM
	db 40 ; MAX_REVIVE
	db 41 ; MAX_ELIXER
	db -1

CollectorTrainingChampionList:
	db 9
	db 33 ; RARE_CANDY
	db 34 ; PP_UP
	db 35 ; HP_UP
	db 36 ; PROTEIN
	db 37 ; IRON
	db 38 ; CARBOS
	db 39 ; CALCIUM
	db 40 ; MAX_REVIVE
	db 41 ; MAX_ELIXER
	db -1

CollectorSpecialList:
	db 9
	db 42 ; MASTER_BALL
	db 43 ; FIRE_STONE
	db 44 ; WATER_STONE
	db 45 ; THUNDERSTONE
	db 46 ; LEAF_STONE
	db 47 ; MOON_STONE
	db 48 ; SUN_STONE
	db 49 ; UP_GRADE
	db 50 ; DRAGON_SCALE
	db -1
