	db 0 ; species ID placeholder

	db  85, 135, 130,  25,  60,  70
	;   hp  atk  def  spd  sat  sdf

	db ROCK, ROCK ; type
	db 45 ; catch rate
	db 232 ; base exp
	db EVERSTONE, HARD_STONE ; items
	db GENDER_F50 ; gender ratio
	db 100 ; unknown 1
	db 15 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/gigalith/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_SLOW ; growth rate
	dn EGG_MINERAL, EGG_MINERAL ; egg groups

	; tm/hm learnset
	tmhm HEADBUTT, TOXIC, ROCK_SMASH, HIDDEN_POWER, SNORE, HYPER_BEAM, PROTECT, FRUSTRATION, SOLARBEAM, EARTHQUAKE, RETURN, MUD_SLAP, DOUBLE_TEAM, SWAGGER, SLEEP_TALK, SANDSTORM, REST, ATTRACT, STRENGTH
	; end
