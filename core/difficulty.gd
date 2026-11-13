class_name Difficulty
extends RefCounted
## The three skill levels: what the menu calls them and how they tilt the
## fight. GameState holds the level chosen for the current run.
##
## Only two things scale, so every level keeps the same enemies, pickups,
## and maps: how much health enemies have, and how hard hits land on the
## player.

## Not "Level": that is the level scene class.
enum Skill { EASY, NORMAL, HARD }

const DEFAULT: Skill = Skill.NORMAL

## Menu row for each level.
const TITLES: Dictionary[Skill, String] = {
	Skill.EASY: "Mother, Hold My Hand",
	Skill.NORMAL: "Sharpen My Blade",
	Skill.HARD: "Hell Fears Me",
}

## Plain-language line shown under the rows for the highlighted level.
const DESCRIPTIONS: Dictionary[Skill, String] = {
	Skill.EASY: "Easy. Enemies hit half as hard and fall sooner.",
	Skill.NORMAL: "Normal. The fight as it was meant to be.",
	Skill.HARD: "Hard. Enemies hit harder and take more killing.",
}

## Scales every hit the player takes.
const PLAYER_DAMAGE_TAKEN: Dictionary[Skill, float] = {
	Skill.EASY: 0.5,
	Skill.NORMAL: 1.0,
	Skill.HARD: 1.5,
}

## Scales EnemyData.max_health.
const ENEMY_HEALTH: Dictionary[Skill, float] = {
	Skill.EASY: 0.75,
	Skill.NORMAL: 1.0,
	Skill.HARD: 1.25,
}


static func title(level: Skill) -> String:
	return TITLES.get(level, TITLES[DEFAULT])


static func description(level: Skill) -> String:
	return DESCRIPTIONS.get(level, DESCRIPTIONS[DEFAULT])


static func player_damage_taken(level: Skill) -> float:
	return PLAYER_DAMAGE_TAKEN.get(level, 1.0)


static func enemy_health(level: Skill) -> float:
	return ENEMY_HEALTH.get(level, 1.0)


## A level read from a save file or anywhere else untrusted: anything that
## isn't one of the three becomes the default.
static func from_variant(value: Variant) -> Skill:
	if value is int and TITLES.has(value):
		return value as Skill
	return DEFAULT
