	db 0 ; species ID placeholder

	db 105,  85,  75,  74,  85,  75
	;   hp  atk  def  spd  sat  sdf

	db WATER, GROUND ; type
	db 45 ; catch rate
	db 229 ; base exp
	db BITTER_BERRY, PSNCUREBERRY ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 20 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/seismitoad/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_SLOW ; growth rate
	dn EGG_WATER_1, EGG_WATER_1 ; egg groups

	; tm/hm learnset
	tmhm TOXIC, ROCK_SMASH, HIDDEN_POWER, SNORE, HYPER_BEAM, ICY_WIND, PROTECT, RAIN_DANCE, FRUSTRATION, EARTHQUAKE, RETURN, DIG, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, SLUDGE_BOMB, REST, ATTRACT, SURF, STRENGTH
	; end
