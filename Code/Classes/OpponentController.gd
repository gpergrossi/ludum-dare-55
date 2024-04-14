# Bot "AI" controller. Casts spells for the enemy periodically. [WIP]
class_name OpponentController extends AbstractSpellCaster

func _ready():
	super();
	teamName = TeamDefs.Enemy.team_name;
