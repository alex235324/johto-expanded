	db 0 ; species ID placeholder

	db  85, 105,  85,  40,  40,  50
	;   hp  atk  def  spd  sat  sdf

	db FIGHTING, FIGHTING ; type
	db 90 ; catch rate
	db 142 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_F25 ; gender ratio
	db 100 ; unknown 1
	db 20 ; step cycles to hatch
	db 5 ; unknown 2
	INCBIN "gfx/pokemon/gurdurr/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_SLOW ; growth rate
	dn EGG_HUMANSHAPE, EGG_HUMANSHAPE ; egg groups

	; tm/hm learnset
	tmhm DYNAMICPUNCH, TOXIC, ROCK_SMASH, HIDDEN_POWER, SUNNY_DAY, SNORE, PROTECT, RAIN_DANCE, FRUSTRATION, RETURN, DIG, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, THUNDERPUNCH, REST, ATTRACT, FIRE_PUNCH, STRENGTH
	; end
