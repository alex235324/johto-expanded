	db 0 ; species ID placeholder

	db  75,  65,  55,  69,  65,  55
	;   hp  atk  def  spd  sat  sdf

	db WATER, GROUND ; type
	db 120 ; catch rate
	db 134 ; base exp
	db BITTER_BERRY, PSNCUREBERRY ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 20 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/palpitoad/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_SLOW ; growth rate
	dn EGG_WATER_1, EGG_WATER_1 ; egg groups

	; tm/hm learnset
	tmhm TOXIC, ROCK_SMASH, HIDDEN_POWER, SNORE, ICY_WIND, PROTECT, RAIN_DANCE, FRUSTRATION, RETURN, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SLUDGE_BOMB, REST, ATTRACT, SURF
	; end
