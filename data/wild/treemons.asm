TreeMons:
; entries correspond to TREEMON_SET_* constants
	table_width 2
	dw TreeMonSet_None
	dw TreeMonSet_Canyon
	dw TreeMonSet_Town
	dw TreeMonSet_Route
	dw TreeMonSet_Kanto
	dw TreeMonSet_Lake
	dw TreeMonSet_Forest
	dw TreeMonSet_Rock
	assert_table_length NUM_TREEMON_SETS
	dw TreeMonSet_None ; unused

; Two tables each (common, rare).
; Structure:
;	db  %, species, level

TreeMonSet_None:
; no encounter data

TreeMonSet_Canyon:
; common
	dbbw 50, 10, SPEAROW
	dbbw 15, 10, TYNAMO ; gen3-5 (was SPEAROW)
	dbbw 15, 10, CARNIVINE ; gen3-5 (was SPEAROW)
	dbbw 10, 10, STUNFISK ; gen3-5 (was AIPOM)
	dbbw  5, 10, KECLEON ; gen3-5 (was AIPOM)
	dbbw  5, 10, AUDINO ; gen3-5 (was AIPOM)
	db -1
; rare
	dbbw 50, 10, SPEAROW
	dbbw 15, 10, RATICATE ; gen3-5 (was HERACROSS)
	dbbw 15, 10, DITTO ; gen3-5 (was HERACROSS)
	dbbw 10, 10, FURRET ; gen3-5 (was AIPOM)
	dbbw  5, 10, PATRAT ; gen3-5 (was AIPOM)
	dbbw  5, 10, RATTATA ; gen3-5 (was AIPOM)
	db -1

TreeMonSet_Town:
; common
	dbbw 50, 10, SPEAROW
	dbbw 15, 10, CARNIVINE ; gen3-5 (was EKANS)
	dbbw 15, 10, STUNFISK ; gen3-5 (was SPEAROW)
	dbbw 10, 10, SENTRET ; gen3-5 (was AIPOM)
	dbbw  5, 10, TYNAMO ; gen3-5 (was AIPOM)
	dbbw  5, 10, ZIGZAGOON ; gen3-5 (was AIPOM)
	db -1
; rare
	dbbw 50, 10, SPEAROW
	dbbw 15, 10, CASTFORM ; gen3-5 (was HERACROSS)
	dbbw 15, 10, BIDOOF ; gen3-5 (was HERACROSS)
	dbbw 10, 10, WURMPLE ; gen3-5 (was AIPOM)
	dbbw  5, 10, VOLBEAT ; gen3-5 (was AIPOM)
	dbbw  5, 10, ILLUMISE ; gen3-5 (was AIPOM)
	db -1

TreeMonSet_Route:
; common
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, CARNIVINE ; gen3-5 (was SPINARAK)
	dbbw 15, 10, SKITTY ; gen3-5 (was LEDYBA)
	dbbw 10, 10, KRICKETOT ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, SNUBBULL ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, JIGGLYPUFF ; gen3-5 (was EXEGGCUTE)
	db -1
; rare
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, SUNKERN ; gen3-5 (was PINECO)
	dbbw 15, 10, SMEARGLE ; gen3-5 (was PINECO)
	dbbw 10, 10, MEOWTH ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, PINECO ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, KECLEON ; gen3-5 (was EXEGGCUTE)
	db -1

TreeMonSet_Kanto:
; common
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, CARNIVINE ; gen3-5 (was EKANS)
	dbbw 15, 10, AUDINO ; gen3-5 (was HOOTHOOT)
	dbbw 10, 10, HOPPIP ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, RATICATE ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, DITTO ; gen3-5 (was EXEGGCUTE)
	db -1
; rare
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, FURRET ; gen3-5 (was PINECO)
	dbbw 15, 10, STANTLER ; gen3-5 (was PINECO)
	dbbw 10, 10, KAKUNA ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, LEDIAN ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, ARIADOS ; gen3-5 (was EXEGGCUTE)
	db -1

TreeMonSet_Lake:
; common
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, CARNIVINE ; gen3-5 (was VENONAT)
	dbbw 15, 10, ZANGOOSE ; gen3-5 (was HOOTHOOT)
	dbbw 10, 10, CHERUBI ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, GLAMEOW ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, STUNFISK ; gen3-5 (was EXEGGCUTE)
	db -1
; rare
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, METAPOD ; gen3-5 (was PINECO)
	dbbw 15, 10, BUTTERFREE ; gen3-5 (was PINECO)
	dbbw 10, 10, AIPOM ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, BURMY ; gen3-5 (was EXEGGCUTE)
	dbbw  5, 10, PATRAT ; gen3-5 (was EXEGGCUTE)
	db -1

TreeMonSet_Forest:
; common
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, EMOLGA ; gen3-5 (was PINECO)
	dbbw 15, 10, RATTATA ; gen3-5 (was PINECO)
	dbbw 10, 10, SENTRET ; gen3-5 (was NOCTOWL)
	dbbw  5, 10, WEEDLE ; gen3-5 (was BUTTERFREE)
	dbbw  5, 10, LEDYBA ; gen3-5 (was BEEDRILL)
	db -1
; rare
	dbbw 50, 10, HOOTHOOT
	dbbw 15, 10, SPINARAK ; gen3-5 (was CATERPIE)
	dbbw 15, 10, TYNAMO ; gen3-5 (was WEEDLE)
	dbbw 10, 10, ZIGZAGOON ; gen3-5 (was HOOTHOOT)
	dbbw  5, 10, CASTFORM ; gen3-5 (was METAPOD)
	dbbw  5, 10, BIDOOF ; gen3-5 (was KAKUNA)
	db -1

TreeMonSet_Rock:
	dbbw 90, 15, KRABBY
	dbbw 10, 15, STUNFISK ; gen3-5 (was SHUCKLE)
	db -1
