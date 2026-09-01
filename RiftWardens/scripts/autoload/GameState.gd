extends Node
## Holds all mutable player state and the game's core loops: gathering,
## crafting, summoning, leveling, and offline progress. Single-player only —
## nothing here talks to a network.

signal resources_changed
signal level_up(new_level: int)
signal chapter_unlocked(chapter: Dictionary)
signal hero_summoned(hero_id: String, is_new: bool, new_hero_level: int)
signal gather_progressed(zone_id: String, material_id: String, fraction: float)
signal offline_gains_ready(summary: Dictionary)

const MAX_OFFLINE_SECONDS := 8 * 60 * 60 # cap idle/offline earnings at 8 hours
const AUTOSAVE_INTERVAL := 30.0

var level := 1
var xp := 0.0
var gold := 100
var essence := 30
var materials: Dictionary = {} # material_id -> int
var owned_heroes: Dictionary = {} # hero_id -> {"level": int}
var forged_items: Dictionary = {} # recipe_id -> int owned
var current_zone_id: String = "ashwood_vale"
var pity_counter := 0
var total_summons := 0
var seen_chapter_levels: Array = []

var _gather_accum := 0.0
var _autosave_accum := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_and_apply_offline_progress()
	set_process(true)

func _process(delta: float) -> void:
	_tick_gathering(delta)
	_autosave_accum += delta
	if _autosave_accum >= AUTOSAVE_INTERVAL:
		_autosave_accum = 0.0
		persist()

func _exit_tree() -> void:
	persist()

# ---------------------------------------------------------------------------
# SAVE / LOAD
# ---------------------------------------------------------------------------

func _load_and_apply_offline_progress() -> void:
	var data := SaveManager.load_game()
	if data.is_empty():
		persist()
		return

	level = int(data.get("level", 1))
	xp = float(data.get("xp", 0.0))
	gold = int(data.get("gold", 100))
	essence = int(data.get("essence", 30))
	materials = data.get("materials", {}).duplicate()
	owned_heroes = data.get("owned_heroes", {}).duplicate(true)
	forged_items = data.get("forged_items", {}).duplicate()
	current_zone_id = String(data.get("current_zone_id", "ashwood_vale"))
	pity_counter = int(data.get("pity_counter", 0))
	total_summons = int(data.get("total_summons", 0))
	seen_chapter_levels = data.get("seen_chapter_levels", []).duplicate()

	var last_online := float(data.get("last_online_unix", Time.get_unix_time_from_system()))
	var elapsed: float = clampf(Time.get_unix_time_from_system() - last_online, 0.0, MAX_OFFLINE_SECONDS)
	if elapsed >= 5.0:
		var summary := _simulate_gathering(elapsed)
		if not summary.is_empty():
			call_deferred("emit_signal", "offline_gains_ready", summary)

func persist() -> void:
	var data := {
		"level": level,
		"xp": xp,
		"gold": gold,
		"essence": essence,
		"materials": materials,
		"owned_heroes": owned_heroes,
		"forged_items": forged_items,
		"current_zone_id": current_zone_id,
		"pity_counter": pity_counter,
		"total_summons": total_summons,
		"seen_chapter_levels": seen_chapter_levels,
		"last_online_unix": Time.get_unix_time_from_system(),
	}
	SaveManager.save_game(data)

# ---------------------------------------------------------------------------
# GATHERING
# ---------------------------------------------------------------------------

func set_current_zone(zone_id: String) -> void:
	if GameData.get_zone(zone_id).is_empty():
		return
	current_zone_id = zone_id
	_gather_accum = 0.0

func get_current_zone() -> Dictionary:
	return GameData.get_zone(current_zone_id)

func gather_speed_multiplier() -> float:
	return 1.0 + get_forge_bonus_pct("gather_pct") / 100.0

func _tick_gathering(delta: float) -> void:
	var zone := get_current_zone()
	if zone.is_empty():
		return
	var seconds_per_unit: float = zone.gather_seconds / gather_speed_multiplier()
	_gather_accum += delta
	if _gather_accum >= seconds_per_unit:
		var units := int(_gather_accum / seconds_per_unit)
		_gather_accum -= units * seconds_per_unit
		for material_id in zone.materials:
			add_material(material_id, units)
	var frac: float = clampf(_gather_accum / seconds_per_unit, 0.0, 1.0)
	if zone.materials.size() > 0:
		emit_signal("gather_progressed", zone.id, zone.materials[0], frac)

## Simulates gathering for `seconds` (used for offline progress) without
## needing per-frame ticks; returns a {material_id: amount} summary.
func _simulate_gathering(seconds: float) -> Dictionary:
	var zone := get_current_zone()
	if zone.is_empty():
		return {}
	var seconds_per_unit: float = zone.gather_seconds / gather_speed_multiplier()
	var units := int(seconds / seconds_per_unit)
	if units <= 0:
		return {}
	var summary := {}
	for material_id in zone.materials:
		add_material(material_id, units)
		summary[material_id] = units
	return summary

func add_material(material_id: String, amount: int) -> void:
	materials[material_id] = int(materials.get(material_id, 0)) + amount
	emit_signal("resources_changed")

func get_material_count(material_id: String) -> int:
	return int(materials.get(material_id, 0))

# ---------------------------------------------------------------------------
# XP / LEVELING
# ---------------------------------------------------------------------------

func add_xp(amount: float) -> void:
	xp += amount
	var leveled := false
	while xp >= GameData.xp_to_next_level(level):
		xp -= GameData.xp_to_next_level(level)
		level += 1
		leveled = true
	emit_signal("resources_changed")
	if leveled:
		emit_signal("level_up", level)
		_check_story_unlocks()

func _check_story_unlocks() -> void:
	var chapter: Dictionary = GameData.get_latest_chapter(level)
	if chapter.is_empty():
		return
	if chapter.required_level in seen_chapter_levels:
		return
	seen_chapter_levels.append(chapter.required_level)
	emit_signal("chapter_unlocked", chapter)

# ---------------------------------------------------------------------------
# CRAFTING
# ---------------------------------------------------------------------------

func get_forge_count(recipe_id: String) -> int:
	return int(forged_items.get(recipe_id, 0))

## Returns the material+gold cost dictionary for the NEXT craft of a recipe,
## scaled up by how many the player already owns.
func get_next_craft_cost(recipe_id: String) -> Dictionary:
	var recipe := GameData.get_recipe(recipe_id)
	if recipe.is_empty():
		return {}
	var mult: float = GameData.forge_cost_multiplier(get_forge_count(recipe_id))
	var mats := {}
	for mat_id in recipe.materials:
		mats[mat_id] = int(ceil(recipe.materials[mat_id] * mult))
	return {"materials": mats, "gold": int(ceil(recipe.gold * mult))}

func can_craft(recipe_id: String) -> bool:
	var recipe := GameData.get_recipe(recipe_id)
	if recipe.is_empty() or level < recipe.required_level:
		return false
	var cost := get_next_craft_cost(recipe_id)
	if gold < cost.gold:
		return false
	for mat_id in cost.materials:
		if get_material_count(mat_id) < cost.materials[mat_id]:
			return false
	return true

func craft(recipe_id: String) -> Dictionary:
	if not can_craft(recipe_id):
		return {"success": false, "message": "Not enough materials or gold."}
	var cost := get_next_craft_cost(recipe_id)
	gold -= cost.gold
	for mat_id in cost.materials:
		materials[mat_id] -= cost.materials[mat_id]
	forged_items[recipe_id] = get_forge_count(recipe_id) + 1
	emit_signal("resources_changed")
	persist()
	return {"success": true, "message": "Forged: %s" % GameData.get_recipe(recipe_id).name}

## Total flat percent bonus from all forged items for a given effect key
## (e.g. "atk_pct", "def_pct", "gather_pct", "summon_pct").
func get_forge_bonus_pct(effect_key: String) -> float:
	var total := 0.0
	for recipe_id in forged_items:
		var recipe := GameData.get_recipe(recipe_id)
		if recipe.is_empty():
			continue
		var per_item: float = recipe.effects.get(effect_key, 0.0)
		total += per_item * forged_items[recipe_id]
	return total

# ---------------------------------------------------------------------------
# HERO SUMMONING
# ---------------------------------------------------------------------------

const SUMMON_COST := 10

func can_afford_summon(count: int = 1) -> bool:
	return essence >= SUMMON_COST * count

func _roll_rarity() -> String:
	pity_counter += 1
	if pity_counter >= GameData.PITY_HARD_CAP:
		pity_counter = 0
		return "legendary"

	var weights := GameData.SUMMON_WEIGHTS.duplicate()
	if pity_counter >= GameData.PITY_SOFT_START:
		var ramp: float = float(pity_counter - GameData.PITY_SOFT_START) / float(GameData.PITY_HARD_CAP - GameData.PITY_SOFT_START)
		weights["legendary"] += ramp * 0.5
		weights["common"] = max(weights["common"] - ramp * 0.5, 0.05)

	var roll := _rng.randf() * _sum_weights(weights)
	var acc := 0.0
	for rarity in GameData.RARITY_ORDER:
		acc += weights[rarity]
		if roll <= acc:
			return rarity
	return "common"

func _sum_weights(weights: Dictionary) -> float:
	var total := 0.0
	for k in weights:
		total += weights[k]
	return total

func summon_single() -> Dictionary:
	if not can_afford_summon():
		return {"success": false, "message": "Not enough Rift Essence."}
	essence -= SUMMON_COST
	var result := _perform_one_summon()
	total_summons += 1
	emit_signal("resources_changed")
	persist()
	return result

func summon_ten() -> Array:
	if not can_afford_summon(10):
		return []
	essence -= SUMMON_COST * 10
	var results := []
	for i in range(10):
		results.append(_perform_one_summon())
	total_summons += 10
	emit_signal("resources_changed")
	persist()
	return results

func _perform_one_summon() -> Dictionary:
	var rarity := _roll_rarity()
	if rarity == "legendary":
		pity_counter = 0
	var pool: Array = GameData.get_heroes_by_rarity(rarity)
	var hero: Dictionary = pool[_rng.randi_range(0, pool.size() - 1)]
	var is_new := not owned_heroes.has(hero.id)
	if is_new:
		owned_heroes[hero.id] = {"level": 1}
	else:
		owned_heroes[hero.id]["level"] = int(owned_heroes[hero.id]["level"]) + 1
	var new_level: int = owned_heroes[hero.id]["level"]
	emit_signal("hero_summoned", hero.id, is_new, new_level)
	return {"success": true, "hero_id": hero.id, "is_new": is_new, "new_level": new_level}

# ---------------------------------------------------------------------------
# HERO ROSTER / POWER
# ---------------------------------------------------------------------------

func get_owned_hero_ids() -> Array:
	return owned_heroes.keys()

func get_hero_level(hero_id: String) -> int:
	return int(owned_heroes.get(hero_id, {}).get("level", 0))

func is_hero_owned(hero_id: String) -> bool:
	return owned_heroes.has(hero_id)

## Sum of ATK+DEF+HP across the whole owned roster, with forge bonuses
## applied — used as the headline "Warband Power" stat.
func get_warband_power() -> int:
	var atk_bonus := 1.0 + get_forge_bonus_pct("atk_pct") / 100.0
	var def_bonus := 1.0 + get_forge_bonus_pct("def_pct") / 100.0
	var total := 0
	for hero_id in owned_heroes:
		var stats := GameData.compute_hero_stats(hero_id, get_hero_level(hero_id))
		total += int(stats.atk * atk_bonus) + int(stats.def * def_bonus) + stats.hp
	return total
