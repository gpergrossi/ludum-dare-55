class_name PlayerController extends Node # For simplicity of testing; intend to remove.

@onready var manabar : ProgressBar = %PlayerManaBarUi;
@onready var sigil: SigilController = %Sigil;

var level := 1;
var maxMana : int;
var mana : float;

func setMana(newAmount):
	mana = newAmount;
	if mana < 0: mana = 0;
	if mana > maxMana: mana = maxMana;
	manabar.value = mana;

func setMaxMana(newMax):
	maxMana = newMax;
	if mana > maxMana: mana = maxMana;
	manabar.max_value = maxMana;

func initMana(lv):
	setMaxMana(Constants.manaByLevel[lv]);
	setMana(maxMana * 0.8);

func regenMana(secondsElapsed : float):
	setMana(mana + PlayerController.getManaRegenPerSecond(level) * secondsElapsed);

func canCast(spell):
	return mana > spell['manaCost']
	
func _on_rune_drawn(rune: Rune, location = null):
	print(rune.canonical_edge_list);
	var spell = Spells.getSpellFor(rune);
	if spell == null: return false;
	return cast(spell, location);

func cast(spell, location = null):
	if !canCast(spell):
		# TODO show low mana warning to player
		return false;
	
	if location == null: 
		location = Spells.defaultTarget[spell['preferredLocation']]

	setMana(mana - spell['manaCost']);
	spell['castFunc'].call(spell, location, TeamDefs.Player.team_name);
	return true;

@warning_ignore("shadowed_variable")
static func getManaRegenPerSecond(lv : int):
	var manaAtLevel : int = Constants.manaByLevel[lv];
	return Constants.manaRegenerationRate / 100.0 * manaAtLevel;

func _ready():
	sigil.rune_drawn.connect(_on_rune_drawn);
	initMana(level);

func _process(delta):
	regenMana(delta);
