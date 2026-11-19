	db 0 ; species ID placeholder

	db  70,  95,  85,  70,  55,  65
	;   hp  atk  def  spd  sat  sdf

	db ROCK, PSYCHIC_TYPE ; type
	db 45 ; catch rate
	db 161 ; base exp
	db NO_ITEM, SUN_STONE ; items
	db GENDER_UNKNOWN ; gender ratio
	db 100 ; unknown 1
	db 25 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/solrock/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_FAST ; growth rate
	dn EGG_MINERAL, EGG_MINERAL ; egg groups

	; tm/hm learnset
	tmhm ROLLOUT, TOXIC, PSYCH_UP, HIDDEN_POWER, SUNNY_DAY, SNORE, HYPER_BEAM, PROTECT, ENDURE, FRUSTRATION, SOLARBEAM, EARTHQUAKE, RETURN, PSYCHIC_M, SHADOW_BALL, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SANDSTORM, FIRE_BLAST, SWIFT, DEFENSE_CURL, DREAM_EATER, REST, FLASH, FLAMETHROWER
	; end
