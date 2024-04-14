# Common elements between PlayerController & EnemyController
# Concerned with things like mana costs, casting spells, etc.
class_name AbstractSpellCaster extends Node

var teamName : String;

var level := 1;
var maxMana : int;
var mana : float;

var last_spell = null

func _ready():
	initMana(level);

func _process(delta):
	regenMana(delta);

static func getManaRegenPerSecond(lv : int):
	var manaAtLevel : int = Constants.manaByLevel[lv];
	return Constants.manaRegenerationRate / 100.0 * manaAtLevel;

func setMana(newAmount : float):
	mana = newAmount;
	if mana < 0: mana = 0;
	if mana > maxMana: mana = maxMana;

func setMaxMana(newMax : int):
	maxMana = newMax;
	if mana > maxMana: mana = maxMana;

func initMana(lv):
	setMaxMana(Constants.manaByLevel[lv]);
	setMana(maxMana * 0.8);

func regenMana(secondsElapsed : float):
	setMana(mana + PlayerController.getManaRegenPerSecond(level) * secondsElapsed);

func canCast(spell):
	return mana > spell['manaCost']

func cast(spell, location = null):
	if !canCast(spell): return false;
	if location == null: location = getDefaultLocation(spell);

	setMana(mana - spell['manaCost']);
	spell['castFunc'].call(spell, location, teamName);
	last_spell = spell
	return true;

func getDefaultLocation(spell):
	var loc = UnitManager._unit_manager_static.summon_default_position_left.global_position;
	loc = Vector2(loc.x, loc.y);
	match spell['preferredLocation']:
		'*': return Vector2.ZERO;
		'ground': return loc;
		'sky': return loc + Vector2(0, -10);
