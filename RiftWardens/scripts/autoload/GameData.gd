extends Node
## Static game content database: classes, heroes, materials, zones, recipes, story.
## Everything here is read-only reference data. Player-owned state lives in GameState.

# ---------------------------------------------------------------------------
# CLASSES
# ---------------------------------------------------------------------------
# atk_mult/def_mult/hp_mult scale a hero's rarity baseline stats by role.
const CLASSES := {
	"warrior": {
		"name": "Warrior",
		"blurb": "Shield-wall veterans who hold the rift line with steel and grit.",
		"color": "#c0392b",
		"atk_mult": 0.90, "def_mult": 1.30, "hp_mult": 1.20,
	},
	"mage": {
		"name": "Mage",
		"blurb": "Scholars of the Arcane Weave who turn the dragons' own fire back on them.",
		"color": "#8e44ad",
		"atk_mult": 1.30, "def_mult": 0.70, "hp_mult": 0.90,
	},
	"ranger": {
		"name": "Ranger",
		"blurb": "Scouts and sharpshooters who strike from beyond the portal's reach.",
		"color": "#27ae60",
		"atk_mult": 1.20, "def_mult": 0.90, "hp_mult": 1.00,
	},
	"cleric": {
		"name": "Cleric",
		"blurb": "Menders of the Dawnlight Order, keeping wardens standing through the long siege.",
		"color": "#f1c40f",
		"atk_mult": 0.80, "def_mult": 1.00, "hp_mult": 1.15,
	},
	"rogue": {
		"name": "Rogue",
		"blurb": "Shadow-runners who slip through rift-static to strike where dragons least expect.",
		"color": "#34495e",
		"atk_mult": 1.25, "def_mult": 0.75, "hp_mult": 0.85,
	},
	"paladin": {
		"name": "Paladin",
		"blurb": "Oath-bound Wardenblades, the first and last line against the Netherworld.",
		"color": "#2980b9",
		"atk_mult": 1.05, "def_mult": 1.15, "hp_mult": 1.15,
	},
}

const CLASS_ORDER := ["warrior", "mage", "ranger", "cleric", "rogue", "paladin"]

# ---------------------------------------------------------------------------
# RARITY
# ---------------------------------------------------------------------------
const RARITY_ORDER := ["common", "rare", "epic", "legendary"]

const RARITY_INFO := {
	"common": {"name": "Common", "color": "#9aa0a6", "stars": 1},
	"rare": {"name": "Rare", "color": "#3498db", "stars": 2},
	"epic": {"name": "Epic", "color": "#9b59b6", "stars": 3},
	"legendary": {"name": "Legendary", "color": "#f39c12", "stars": 4},
}

# Base ATK/DEF/HP at hero level 1, before class multipliers.
const RARITY_BASELINE := {
	"common": {"atk": 8, "def": 6, "hp": 60},
	"rare": {"atk": 12, "def": 9, "hp": 90},
	"epic": {"atk": 18, "def": 14, "hp": 140},
	"legendary": {"atk": 26, "def": 20, "hp": 210},
}

# Summon odds by rarity tier (must sum to 1.0). Within a tier, heroes are
# picked uniformly at random from that tier's pool.
const SUMMON_WEIGHTS := {
	"common": 0.55,
	"rare": 0.32,
	"epic": 0.10,
	"legendary": 0.03,
}

# Soft pity: after this many single summons without a legendary, legendary
# odds ramp up linearly to guarantee one by PITY_HARD_CAP.
const PITY_SOFT_START := 40
const PITY_HARD_CAP := 60

# ---------------------------------------------------------------------------
# HEROES (48: 8 per class, 3 common / 3 rare / 1 epic / 1 legendary each)
# ---------------------------------------------------------------------------
const HEROES := [
	# --- Warrior ---
	{"id": "war_bram", "name": "Bram Stonewell", "class_id": "warrior", "rarity": "common", "tagline": "Never took a step back in his life."},
	{"id": "war_talia", "name": "Talia Ironbrace", "class_id": "warrior", "rarity": "common", "tagline": "Forged her own armor, dents and all."},
	{"id": "war_corin", "name": "Corin Ashfield", "class_id": "warrior", "rarity": "common", "tagline": "Lost his farm to a rift. Kept his temper."},
	{"id": "war_dagren", "name": "Dagren Halloway", "class_id": "warrior", "rarity": "rare", "tagline": "Broke a dragon's wing-claw with a shield bash."},
	{"id": "war_vesna", "name": "Vesna Coldiron", "class_id": "warrior", "rarity": "rare", "tagline": "Duels rift-spawn for sport. Wins for a living."},
	{"id": "war_petrus", "name": "Petrus Vane", "class_id": "warrior", "rarity": "rare", "tagline": "The line holds where Petrus stands."},
	{"id": "war_kaida", "name": "Kaida Emberguard", "class_id": "warrior", "rarity": "epic", "tagline": "Survived a Netherember blast. Wears the scar as a medal."},
	{"id": "war_aurelian", "name": "Aurelian Steelheart", "class_id": "warrior", "rarity": "legendary", "tagline": "Founder-blood of the Wardens. The line that never breaks."},

	# --- Mage ---
	{"id": "mag_nera", "name": "Nera Duskwhisper", "class_id": "mage", "rarity": "common", "tagline": "Learned fire-weaving to keep her hands warm. Kept going."},
	{"id": "mag_ollan", "name": "Ollan Frostpage", "class_id": "mage", "rarity": "common", "tagline": "Reads rift-static like other people read weather."},
	{"id": "mag_ivy", "name": "Ivy Cassock", "class_id": "mage", "rarity": "common", "tagline": "Apprentice by title, front-line by necessity."},
	{"id": "mag_marek", "name": "Marek Voidquill", "class_id": "mage", "rarity": "rare", "tagline": "Writes counter-sigils faster than dragons can breathe."},
	{"id": "mag_sable", "name": "Sable Thornwick", "class_id": "mage", "rarity": "rare", "tagline": "Turned a hatchling's own flame back on it. Once."},
	{"id": "mag_yuna", "name": "Yuna Emberlace", "class_id": "mage", "rarity": "rare", "tagline": "Weaves fire into lace. Somehow it still burns."},
	{"id": "mag_corvin", "name": "Corvin Starbind", "class_id": "mage", "rarity": "epic", "tagline": "Bound a minor rift shut with nothing but starlight and spite."},
	{"id": "mag_seraphine", "name": "Seraphine Vex", "class_id": "mage", "rarity": "legendary", "tagline": "The Weave answers her before she finishes asking."},

	# --- Ranger ---
	{"id": "ran_finch", "name": "Finch Alderwood", "class_id": "ranger", "rarity": "common", "tagline": "Can hit a rift-moth out of the air at fifty paces."},
	{"id": "ran_roan", "name": "Roan Swiftarrow", "class_id": "ranger", "rarity": "common", "tagline": "Outran a brushfire once. Doesn't like to talk about it."},
	{"id": "ran_lira", "name": "Lira Brackenfall", "class_id": "ranger", "rarity": "common", "tagline": "Knows every game trail within three days of Ashwood Vale."},
	{"id": "ran_dashiell", "name": "Dashiell Hollowmark", "class_id": "ranger", "rarity": "rare", "tagline": "Tracks dragons by the ash they leave, not the ash they make."},
	{"id": "ran_wren", "name": "Wren Nightglade", "class_id": "ranger", "rarity": "rare", "tagline": "One arrow, one joint, every time."},
	{"id": "ran_oskar", "name": "Oskar Farrow", "class_id": "ranger", "rarity": "rare", "tagline": "Built his own bow from a felled rift-tree. It hums."},
	{"id": "ran_sylvane", "name": "Sylvane Quickfeather", "class_id": "ranger", "rarity": "epic", "tagline": "Put three shafts through a wyrm's eye before it blinked."},
	{"id": "ran_kestrel", "name": "Kestrel Duskrunner", "class_id": "ranger", "rarity": "legendary", "tagline": "The Netherdeep has a bounty on her. She's flattered."},

	# --- Cleric ---
	{"id": "cle_elowen", "name": "Elowen Brightvow", "class_id": "cleric", "rarity": "common", "tagline": "Took her vows the week the first rift opened."},
	{"id": "cle_tomas", "name": "Tomas Whitfield", "class_id": "cleric", "rarity": "common", "tagline": "Patched up half the garrison. Twice, some of them."},
	{"id": "cle_anwen", "name": "Anwen Dovekeep", "class_id": "cleric", "rarity": "common", "tagline": "Sings the old wardwrite hymns. They still work."},
	{"id": "cle_aldric", "name": "Brother Aldric", "class_id": "cleric", "rarity": "rare", "tagline": "Walked out of a collapsed rift-shrine carrying two wounded."},
	{"id": "cle_mira", "name": "Mira Sunwarden", "class_id": "cleric", "rarity": "rare", "tagline": "Her light burns dragonfire cold before it lands."},
	{"id": "cle_percival", "name": "Percival Lowe", "class_id": "cleric", "rarity": "rare", "tagline": "Keeps every warden's name in a little worn book."},
	{"id": "cle_isolde", "name": "Isolde Dawnbringer", "class_id": "cleric", "rarity": "epic", "tagline": "Held the line's wounded together through the Cinder Wastes siege."},
	{"id": "cle_theodric", "name": "Theodric the Unbroken", "class_id": "cleric", "rarity": "legendary", "tagline": "Has died twice by the field surgeons' count. Argues it was once."},

	# --- Rogue ---
	{"id": "rog_jax", "name": "Jax Nettleback", "class_id": "rogue", "rarity": "common", "tagline": "Picked a dragon cultist's pocket mid-ritual."},
	{"id": "rog_piper", "name": "Piper Quickfingers", "class_id": "rogue", "rarity": "common", "tagline": "Faster hands than sense, most days."},
	{"id": "rog_renn", "name": "Renn Blackfeather", "class_id": "rogue", "rarity": "common", "tagline": "Moves like the rift-static isn't even watching."},
	{"id": "rog_vipera", "name": "Vipera Cross", "class_id": "rogue", "rarity": "rare", "tagline": "Three knives, one throw, no wasted motion."},
	{"id": "rog_otto", "name": "Otto Wickthorn", "class_id": "rogue", "rarity": "rare", "tagline": "Robbed a Dragon Court envoy blind before the ambush even started."},
	{"id": "rog_dahlia", "name": "Dahlia Voss", "class_id": "rogue", "rarity": "rare", "tagline": "Left a calling card on a hatchling's own hoard."},
	{"id": "rog_nyx", "name": "Nyx Shadowmere", "class_id": "rogue", "rarity": "epic", "tagline": "The Court has stopped sending envoys through that pass."},
	{"id": "rog_corvax", "name": "Corvax the Silent", "class_id": "rogue", "rarity": "legendary", "tagline": "No one has heard him speak. Everyone has heard him win."},

	# --- Paladin ---
	{"id": "pal_garrick", "name": "Garrick Dawnshield", "class_id": "paladin", "rarity": "common", "tagline": "Swore the Warden's Oath before he could grow a beard."},
	{"id": "pal_beatrix", "name": "Beatrix Lionhart", "class_id": "paladin", "rarity": "common", "tagline": "Carried the banner through the Marsh when it fell twice."},
	{"id": "pal_osric", "name": "Osric Trueblade", "class_id": "paladin", "rarity": "common", "tagline": "Believes every rift can be closed. So far, correct."},
	{"id": "pal_ysolde", "name": "Dame Ysolde", "class_id": "paladin", "rarity": "rare", "tagline": "Knighted on the field, mid-siege, still fighting."},
	{"id": "pal_cassian", "name": "Cassian Brightoath", "class_id": "paladin", "rarity": "rare", "tagline": "His oath has outlasted three commanders."},
	{"id": "pal_fenwick", "name": "Fenwick Stormguard", "class_id": "paladin", "rarity": "rare", "tagline": "Turned a hatchling brood back at the Ironvein gate alone."},
	{"id": "pal_solveig", "name": "Solveig Radiance", "class_id": "paladin", "rarity": "epic", "tagline": "Her blade catches rift-light like it belongs to her."},
	{"id": "pal_thane", "name": "Commander Thane Direwatch", "class_id": "paladin", "rarity": "legendary", "tagline": "Led the Wardens since the first sky-tear. Still standing at the front."},
]

# ---------------------------------------------------------------------------
# MATERIALS
# ---------------------------------------------------------------------------
const MATERIALS := {
	"ashwood_log": {"name": "Ashwood Log", "tier": 1, "color": "#8d6e63"},
	"wild_herb": {"name": "Wild Herb", "tier": 1, "color": "#66bb6a"},
	"iron_ore": {"name": "Iron Ore", "tier": 2, "color": "#78909c"},
	"flint_shard": {"name": "Flint Shard", "tier": 2, "color": "#546e7a"},
	"marsh_reed": {"name": "Marsh Reed", "tier": 3, "color": "#558b2f"},
	"murk_pearl": {"name": "Murk Pearl", "tier": 3, "color": "#4db6ac"},
	"cinder_dust": {"name": "Cinder Dust", "tier": 4, "color": "#e64a19"},
	"obsidian_chunk": {"name": "Obsidian Chunk", "tier": 4, "color": "#37474f"},
	"rift_shard": {"name": "Rift Shard", "tier": 5, "color": "#7e57c2"},
	"voidglass": {"name": "Voidglass", "tier": 5, "color": "#5c6bc0"},
	"netherember": {"name": "Netherember", "tier": 6, "color": "#d32f2f"},
	"dragonscale_fragment": {"name": "Dragonscale Fragment", "tier": 6, "color": "#c0392b"},
}

# ---------------------------------------------------------------------------
# GATHERING ZONES
# ---------------------------------------------------------------------------
# gather_seconds: time to gather one unit of a material while active/idle.
const ZONES := [
	{
		"id": "ashwood_vale", "name": "Ashwood Vale", "required_level": 1,
		"materials": ["ashwood_log", "wild_herb"], "gather_seconds": 4.0,
		"blurb": "Scorched woodland at the edge of the first rift-fall.",
	},
	{
		"id": "ironvein_hollow", "name": "Ironvein Hollow", "required_level": 5,
		"materials": ["iron_ore", "flint_shard"], "gather_seconds": 6.0,
		"blurb": "An old mine, reopened to arm the Warden garrisons.",
	},
	{
		"id": "sunken_marsh", "name": "Sunken Marsh", "required_level": 10,
		"materials": ["marsh_reed", "murk_pearl"], "gather_seconds": 8.0,
		"blurb": "Rift-static pools in the low water here, and stranger things with it.",
	},
	{
		"id": "cinder_wastes", "name": "Cinder Wastes", "required_level": 15,
		"materials": ["cinder_dust", "obsidian_chunk"], "gather_seconds": 10.0,
		"blurb": "Ground the dragons scoured flat. Still smoulders.",
	},
	{
		"id": "rift_scar", "name": "Rift Scar", "required_level": 22,
		"materials": ["rift_shard", "voidglass"], "gather_seconds": 14.0,
		"blurb": "A tear in the world that never quite finished closing.",
	},
	{
		"id": "netherward_approach", "name": "Netherward Approach", "required_level": 30,
		"materials": ["netherember", "dragonscale_fragment"], "gather_seconds": 20.0,
		"blurb": "The last mile before Nethergate itself. The Court patrols here.",
	},
]

# ---------------------------------------------------------------------------
# CRAFTING RECIPES
# ---------------------------------------------------------------------------
# Crafted items are permanent, stackable Warden Forge upgrades that boost the
# whole roster. Cost scales up each time one is forged (see GameState).
const RECIPES := [
	{
		"id": "ashwood_blade", "name": "Ashwood Training Blade", "required_level": 1,
		"materials": {"ashwood_log": 5, "wild_herb": 2}, "gold": 20,
		"effects": {"atk_pct": 1.0}, "blurb": "Rough, but it holds an edge.",
	},
	{
		"id": "ashwood_wraps", "name": "Ashwood Leather Wraps", "required_level": 2,
		"materials": {"ashwood_log": 4, "wild_herb": 4}, "gold": 20,
		"effects": {"hp_pct": 1.0}, "blurb": "Boiled leather, herb-treated against rift-burn.",
	},
	{
		"id": "ironvein_pick", "name": "Ironvein War Pick", "required_level": 5,
		"materials": {"iron_ore": 6, "flint_shard": 3}, "gold": 60,
		"effects": {"atk_pct": 1.5}, "blurb": "Mined it, then swung it. Efficient.",
	},
	{
		"id": "ironvein_barding", "name": "Ironvein Plate Barding", "required_level": 6,
		"materials": {"iron_ore": 8, "flint_shard": 2}, "gold": 60,
		"effects": {"def_pct": 1.5}, "blurb": "Heavy. Reliable. Warden standard-issue.",
	},
	{
		"id": "marshlight_charm", "name": "Marshlight Charm", "required_level": 10,
		"materials": {"marsh_reed": 6, "murk_pearl": 2}, "gold": 150,
		"effects": {"gather_pct": 2.0}, "blurb": "The pearl-light shows you where the good patches are.",
	},
	{
		"id": "cinderforged_axe", "name": "Cinderforged Greataxe", "required_level": 15,
		"materials": {"cinder_dust": 8, "obsidian_chunk": 4}, "gold": 300,
		"effects": {"atk_pct": 2.5}, "blurb": "Quenched in dragon-scorched ash. Never dulls.",
	},
	{
		"id": "riftglass_amulet", "name": "Riftglass Amulet", "required_level": 22,
		"materials": {"rift_shard": 5, "voidglass": 5}, "gold": 600,
		"effects": {"summon_pct": 2.0}, "blurb": "Hums faintly. Draws stray essence toward you.",
	},
	{
		"id": "netherbane_standard", "name": "Netherbane Standard", "required_level": 30,
		"materials": {"netherember": 6, "dragonscale_fragment": 3}, "gold": 1200,
		"effects": {"atk_pct": 2.0, "def_pct": 3.0}, "blurb": "Plant it and the whole line steadies.",
	},
]

# ---------------------------------------------------------------------------
# STORY — "The Dragon Court of the Netherdeep"
# ---------------------------------------------------------------------------
const STORY_CHAPTERS := [
	{"required_level": 1, "title": "The Sky Tore Open", "text": "It started with a light over Ashwood Vale that shouldn't have been there. By morning there was a hole in the sky, and something with wings the size of a barn roof was circling it. The Rift Wardens are recruiting. You didn't have much choice — the Vale doesn't exist anymore, not the way it did."},
	{"required_level": 5, "title": "Embers on the Wind", "text": "Ironvein Hollow's miners found the first hatchling nest two levels down, curled around a crack in the rock that pulsed like a heartbeat. The Wardens sealed the tunnel. It didn't stay sealed. Whatever is coming through these rifts, it isn't lost — it's looking for something."},
	{"required_level": 10, "title": "The Marsh Remembers", "text": "The Sunken Marsh was rift-touched decades before the sky ever tore — the old maps mark it 'unsound ground' and leave it at that. Now the murk-pearls glow at night, and the wardwrite hymns the clerics sing are older than the Order itself. Something down there has been waiting."},
	{"required_level": 15, "title": "Cinder and Ash", "text": "A full wing of the Dragon Court came through at the Cinder Wastes — not scouts, not stragglers. An offensive. The garrison held, barely, and for the first time a captured dragonkin spoke a word the field scribes recognized: Netherdeep. A name for where they're from."},
	{"required_level": 20, "title": "Whispers Through the Rift", "text": "Warden scryers have started catching fragments of speech bleeding through the smaller rifts before they close — voices, plans, a court in session. The Dragon Court isn't raiding at random. Every rift they open is a foothold, and every foothold points toward one place: a gate old enough to have a name."},
	{"required_level": 22, "title": "The Scar Widens", "text": "Rift Scar used to be a half-day's ride from anywhere. Now it's a wound that doesn't close, wide enough to march an army through, and the Court has started doing exactly that. The Wardens' orders change: stop reacting to rifts. Find the source."},
	{"required_level": 26, "title": "The Dragon Court's Envoy", "text": "An envoy came through under a banner of parley — the first the Court has ever sent. Its message was simple: stand down, and the Netherdeep would leave the surface world its edges. Keep fighting, and it would take all of it. The Wardens sent the envoy back with an answer of their own."},
	{"required_level": 30, "title": "Netherward Approach", "text": "The approach to Nethergate is the most heavily held ground the Wardens have ever pushed toward — patrols in strength, wards on every stone, dragonkin who don't scatter when you engage them. This close to the source, the Court isn't defending territory. It's defending a door."},
	{"required_level": 35, "title": "The First Seal", "text": "Warden scholars, working from captured Court sigils, found a way to weaken Nethergate from the outside: three seals, laid by whoever built the gate in the first place, half-buried and half-forgotten. The first one held true the moment a Warden's hand touched it. There are two more."},
	{"required_level": 40, "title": "March of the Wardens", "text": "For the first time since the sky tore, the Wardens march on the Netherdeep's own ground instead of waiting for it to come to theirs. Every hero who's answered the summons rides in this column — warriors, mages, rangers, clerics, rogues, paladins, shoulder to shoulder. It doesn't feel like enough. It's what there is."},
	{"required_level": 45, "title": "The Last Ember", "text": "The second seal was guarded by something the Court calls the Hollow Sovereign's own Emberguard — the dragons that don't leave the Netherdeep for anything short of this. The fight for it will be told for generations, one way or another. It held. Barely. One seal left."},
	{"required_level": 50, "title": "Nethergate", "text": "The gate itself is smaller than the stories made it sound — a black seam in the world, cold where fire should be. The third seal waits at its heart, and beyond it, if the captured envoy told the truth, the Hollow Sovereign itself. The Wardens have never been this close to closing it for good. This is where that fight begins. (End of the current chapter arc — more to come.)"},
]

# ---------------------------------------------------------------------------
# ACCESSORS
# ---------------------------------------------------------------------------

func get_class_info(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {})

func get_hero(hero_id: String) -> Dictionary:
	for h in HEROES:
		if h.id == hero_id:
			return h
	return {}

func get_heroes_by_rarity(rarity: String) -> Array:
	return HEROES.filter(func(h): return h.rarity == rarity)

func get_material(material_id: String) -> Dictionary:
	return MATERIALS.get(material_id, {})

func get_zone(zone_id: String) -> Dictionary:
	for z in ZONES:
		if z.id == zone_id:
			return z
	return {}

func get_unlocked_zones(level: int) -> Array:
	return ZONES.filter(func(z): return level >= z.required_level)

func get_recipe(recipe_id: String) -> Dictionary:
	for r in RECIPES:
		if r.id == recipe_id:
			return r
	return {}

func get_unlocked_recipes(level: int) -> Array:
	return RECIPES.filter(func(r): return level >= r.required_level)

func get_unlocked_chapters(level: int) -> Array:
	return STORY_CHAPTERS.filter(func(c): return level >= c.required_level)

func get_latest_chapter(level: int) -> Dictionary:
	var unlocked := get_unlocked_chapters(level)
	return unlocked.back() if unlocked.size() > 0 else {}

## Computed ATK/DEF/HP for a hero at a given hero level (levels add flat %
## growth per level so idle progress still means something for owned heroes).
func compute_hero_stats(hero_id: String, hero_level: int) -> Dictionary:
	var hero := get_hero(hero_id)
	if hero.is_empty():
		return {"atk": 0, "def": 0, "hp": 0}
	var baseline: Dictionary = RARITY_BASELINE[hero.rarity]
	var cls: Dictionary = CLASSES[hero.class_id]
	var level_mult: float = 1.0 + float(max(hero_level, 1) - 1) * 0.08
	return {
		"atk": int(round(baseline.atk * cls.atk_mult * level_mult)),
		"def": int(round(baseline.def * cls.def_mult * level_mult)),
		"hp": int(round(baseline.hp * cls.hp_mult * level_mult)),
	}

## XP required to go from player level `level` to `level + 1`.
func xp_to_next_level(level: int) -> int:
	return int(round(50 * pow(level, 1.45))) + 25

## Forge (recipe) cost multiplier for the Nth copy already owned (0-indexed).
func forge_cost_multiplier(owned_count: int) -> float:
	return pow(1.15, owned_count)
