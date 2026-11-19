	db 0 ; species ID placeholder

	db  71, 120,  95,  99, 120,  95
	;   hp  atk  def  spd  sat  sdf

	db BUG, STEEL ; type
	db 3 ; catch rate
	db 255 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_UNKNOWN ; gender ratio
	db 100 ; unknown 1
	db 120 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/genesect/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_SLOW ; growth rate
	dn EGG_NONE, EGG_NONE ; egg groups

	; tm/hm learnset
	tmhm TOXIC, ZAP_CANNON, HIDDEN_POWER, SNORE, BLIZZARD, HYPER_BEAM, PROTECT, GIGA_DRAIN, FRUSTRATION, SOLARBEAM, THUNDER, RETURN, PSYCHIC_M, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, REST, FURY_CUTTER, FLY, FLASH, FLAMETHROWER, THUNDERBOLT, ICE_BEAM
	; end
