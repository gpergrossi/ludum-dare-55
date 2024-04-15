# Common elements between PlayerController & EnemyController
# Concerned with things like mana costs, casting spells, etc.
class_name AbstractSpellCaster extends Node

var teamName : String;

var level : int
var maxMana : int;
var mana : float;

@export var maxHealth := 100.0
var health : float
@export var healthBar : Progressbar3d

var last_spell = null

var _already_died := false
signal died

func _ready():
	level = LevelLoader.current_level
	initMana(level);
	setHealth(maxHealth)

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

func canCast(spell, _location):
	return mana > spell['manaCost']

func cast(spell, location = null):
	if !canCast(spell, location): return false;
	if location == null: location = getDefaultLocation(spell);

	setMana(mana - spell['manaCost']);
	spell['castFunc'].call(spell, location, teamName);
	last_spell = spell
	return true;

func getDefaultLocation(spell):
	var loc = UnitManager._unit_manager_static.summon_default_position_left.global_position;
	loc = Vector2(loc.x, loc.y);
	match spell['preferredLocation']:
		'none': return loc
		'*': return Vector2.ZERO;
		'ground': return loc;
		'sky': return loc + Vector2(0, -10);
	assert(false, "no default location for %s" % spell['preferredLocation'])

func setHealth(new_health : float) -> void:
	health = clamp(new_health, 0, maxHealth)
	healthBar.fraction = health / maxHealth
	if health == 0.0 and not _already_died:
		_already_died = true
		died.emit()
