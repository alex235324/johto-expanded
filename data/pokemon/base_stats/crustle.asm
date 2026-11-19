	db 0 ; species ID placeholder

	db  70,  95, 125,  45,  65,  75
	;   hp  atk  def  spd  sat  sdf

	db BUG, ROCK ; type
	db 75 ; catch rate
	db 170 ; base exp
	db NO_ITEM, HARD_STONE ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 20 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/crustle/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_BUG, EGG_MINERAL ; egg groups

	; tm/hm learnset
	tmhm TOXIC, ROCK_SMASH, HIDDEN_POWER, SNORE, HYPER_BEAM, PROTECT, FRUSTRATION, SOLARBEAM, EARTHQUAKE, RETURN, DIG, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SANDSTORM, REST, ATTRACT, CUT, STRENGTH
	; end
