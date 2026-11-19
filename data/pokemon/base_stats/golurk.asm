	db 0 ; species ID placeholder

	db  89, 124,  80,  55,  55,  80
	;   hp  atk  def  spd  sat  sdf

	db GROUND, GHOST ; type
	db 90 ; catch rate
	db 169 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_UNKNOWN ; gender ratio
	db 100 ; unknown 1
	db 25 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/golurk/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_MINERAL, EGG_MINERAL ; egg groups

	; tm/hm learnset
	tmhm DYNAMICPUNCH, CURSE, ROLLOUT, TOXIC, ROCK_SMASH, HIDDEN_POWER, SNORE, HYPER_BEAM, ICY_WIND, PROTECT, RAIN_DANCE, FRUSTRATION, SOLARBEAM, EARTHQUAKE, RETURN, PSYCHIC_M, SHADOW_BALL, MUD_SLAP, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, DEFENSE_CURL, THUNDERPUNCH, REST, THIEF, FIRE_PUNCH, FLY, STRENGTH, FLASH, THUNDERBOLT, ICE_BEAM
	; end
