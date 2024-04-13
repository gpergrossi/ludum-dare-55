class_name PlayerController extends AbstractSpellCaster

@onready var manabar : ProgressBar = %PlayerManaBarUi;
@onready var sigil: SigilController = %Sigil;
	
func _on_rune_drawn(rune: Rune, location = null):
	print(rune.canonical_edge_list);
	var spell = Spells.getSpellFor(rune);
	if spell == null: return false;
	return cast(spell, location);

func _ready():
	super();
	sigil.rune_drawn.connect(_on_rune_drawn);
	teamName = TeamDefs.Player.team_name;

func setMana(newAmount : float):
	super(newAmount);
	manabar.value = mana;

func setMaxMana(newMax : int):
	super(newMax);
	manabar.max_value = maxMana;

func cast(spell, location = null):
	if !canCast(spell):
		# TODO show low mana warning to player
		pass;
	return super(spell, location);
