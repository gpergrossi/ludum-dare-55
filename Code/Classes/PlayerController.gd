class_name PlayerController extends Node # For simplicity of testing; intend to remove.

var level := 1;
var maxMana : int;
var mana : float;

func initMana(lv):
	maxMana = Constants.manaByLevel[lv];
	mana = maxMana * 0.8;

func regenMana(secondsElapsed : float):
	mana += getManaRegenPerSecond(maxMana) * secondsElapsed

func canCast(spell):
	return mana > spell['manaCost']
	
func onRuneDrawn(rune, location: Vector2):
	var spell = Spells.getSpellFor(rune);
	cast(spell, location);

func cast(spell, location: Vector2 = Vector2.ZERO):
	if !canCast(spell):
		# TODO show low mana warning to player
		return;
	mana -= spell['manaCost'];
	# TODO redraw mana bar UI
	spell['castFunc'].call(spell, location, 'player');
	

@warning_ignore("shadowed_variable")
static func getManaRegenPerSecond(maxMana : int):
	return Constants.manaRegenerationRate / 100.0 * maxMana;



# Everything below this comment for dev testing only, intended to be removed.
# Once complete, will hopefully just be an Object (not Node) which other classes
# (e.g. SigilsController) access and invoke functions.

func _ready():
	# TODO move initMana() call into analogous intiialization method,
	#      when PlayerController stops being a Node
	initMana(level);

	debugOut();

func _process(delta):
	# TODO will need to invoke regenMana from SOMEWHERE,
	#      if PlayerController stops being a Node
	regenMana(delta);

func debugOut():
	print(mana)
	print(canCast(Spells.summonBasicWalker))
	cast(Spells.summonBasicWalker)
