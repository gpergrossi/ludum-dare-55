class_name PlayerController extends AbstractSpellCaster

@onready var manabar : ProgressBar = %PlayerManaBarUi;
@onready var sigil: SigilController = %Sigil;
@onready var position_selector := %PositionSelector

func _on_rune_drawn(rune: Rune):
	print(rune.canonical_edge_list);
	var spell = null
	if rune.canonical_edge_list == Spells.recastRune.canonical_edge_list:
		spell = last_spell
	else:
		spell = Spells.getSpellFor(rune)
	if spell == null: return false;
	
	if not canCast(spell, null): return false
	
	var location = null
	if spell['preferredLocation'] != 'none':
		sigil.is_interactable = false
		sigil.hide()
		location = await position_selector.select_position()
		sigil.show()
		sigil.is_interactable = true
	
	return cast(spell, location);

func _ready():
	super();
	sigil.rune_drawn.connect(_on_rune_drawn);
	died.connect(_on_died)
	teamName = TeamDefs.Player.team_name;

func setMana(newAmount : float):
	super(newAmount);
	manabar.value = mana;

func setMaxMana(newMax : int):
	super(newMax);
	manabar.max_value = maxMana;

func cast(spell, location = null):
	if !canCast(spell, location):
		# TODO show low mana warning to player
		pass;
	return super(spell, location);

func _on_died() -> void:
	%AnnounceLabel.text = "You lose :'( - retrying level %d" % LevelLoader.current_level
	await get_tree().create_timer(5.0).timeout
	# TODO race condition between winning, losing, and moving to the next level.
	LevelLoader.load_level(LevelLoader.current_level)
