# Rift Wardens

An offline idle RPG crafting game built in **Godot 4.3**. No accounts, no
login, no chat, no guilds — just one player, a warband of summoned heroes,
and a world the Dragon Court is tearing open from the Netherworld.

This is a fresh, standalone game project living at the repo root under
`RiftWardens/`. It does not touch or depend on the rest of this repository
(the 2009scape RuneScape server/client) in any way.

## Story

*The Dragon Court of the Netherdeep*

A rift tore open the sky over Ashwood Vale, and the Dragon Court has been
pouring through ever since. You're a fresh recruit of the Rift Wardens,
gathering materials, forging gear, and summoning heroes to push back the
invasion zone by zone — Ashwood Vale, Ironvein Hollow, Sunken Marsh, Cinder
Wastes, Rift Scar — all the way to Nethergate itself, where the Court's
portal to the Netherworld has to be sealed for good.

12 story chapters unlock automatically as you level up (see
`scripts/autoload/GameData.gd` → `STORY_CHAPTERS`), told through the Story
tab. No fetch quests or dialogue trees needed — it's flavor text that
rewards playing, not a separate system to build.

## Core loop

1. **Gather** — pick an unlocked zone; materials accumulate automatically
   over time, in real time, whether the app is open or not (capped at 8
   hours of offline progress, shown as a "welcome back" summary on launch).
2. **Craft** — spend materials + gold at the Warden Forge to craft permanent
   roster-wide upgrades (ATK/DEF/gather-speed/essence-gain bonuses). Costs
   scale up 15% each time you craft another copy of the same item, standard
   idle-game pacing.
3. **Summon** — spend Rift Essence (earned from playing, never purchased) to
   summon heroes from a pool of 48, across 6 classes and 4 rarity tiers.
   Duplicate summons level up the hero instead of being wasted. A soft-pity
   system guarantees a Legendary within 60 summons.
4. **Level up** — gathering and crafting grant XP; leveling unlocks new
   zones, new recipes, and new story chapters.

No multiplayer surface exists anywhere in this build — no chat, no guilds,
no leaderboards, no server calls. Everything runs from a local JSON save in
`user://savegame.json`.

## Content at a glance

- **6 classes**: Warrior, Mage, Ranger, Cleric, Rogue, Paladin — each with a
  distinct ATK/DEF/HP multiplier profile (see `CLASSES` in `GameData.gd`).
- **48 heroes**: 8 per class (3 Common / 3 Rare / 1 Epic / 1 Legendary
  each), every one with a name and a one-line tagline tying back to the
  story.
- **6 gathering zones**, **12 materials**, **8 forge recipes**, all gated by
  player level so progression and story unlocks line up.

All of this is defined as data in `scripts/autoload/GameData.gd` — adding a
49th hero, a 7th zone, or a 13th story chapter is a matter of adding one
entry to an array, not writing new systems.

## Project layout

```
RiftWardens/
  project.godot            # Godot 4.3 project config (portrait, mobile renderer)
  export_presets.cfg        # Android export preset template (fill in your keystore)
  scripts/
    autoload/
      GameData.gd           # static content: classes, heroes, materials, zones, recipes, story
      GameState.gd           # player state + gathering/crafting/summoning/leveling logic
      SaveManager.gd         # local JSON save/load, no network
    ui/
      Main.gd                # top bar (level/gold/essence/power) + tab shell + toasts/popup
      GatherPanel.gd, CraftPanel.gd, HeroesPanel.gd, SummonPanel.gd, StoryPanel.gd
  scenes/
    Main.tscn                # app entry scene (set as run/main_scene)
    ui/*.tscn                 # one scene per tab, instanced into Main.tscn
  assets/icons/icon.svg       # placeholder app icon — replace before shipping
```

## Running it

Open `RiftWardens/` as a project in the Godot 4.3+ editor and press Play, or
headless-smoke-test it from the command line:

```
godot4 --headless --path RiftWardens
```

(No window will appear in headless mode; this is only useful for CI-style
script validation, not for actually playing.)

## Exporting to Google Play

1. Install the Godot **Android export templates** matching your editor
   version (Editor → Manage Export Templates), plus the Android SDK
   command-line tools, a JDK, and Gradle — Godot's own
   [Android export docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
   walk through the one-time setup.
2. In `export_presets.cfg`, set `package/unique_name` to your real reverse-
   domain package id (it's currently a placeholder,
   `com.riftwardens.game`), and generate/point at your own upload keystore
   under `keystore/release` and `keystore/release_user` (do **not** commit a
   real keystore or its passwords to this repo).
3. From the editor: **Project → Export → Android → Export Project**, output
   format **App Bundle (.aab)** — Play Store requires AAB, not APK, for new
   apps.
4. Upload the `.aab` to a new app in the
   [Google Play Console](https://play.google.com/console), fill in the
   store listing (this build ships a placeholder icon/screenshots — replace
   those before submitting), and run it through Internal Testing before any
   public track.

No `INTERNET` or network permissions are requested (see
`export_presets.cfg`) since the game is fully offline — keep it that way
unless you add a feature that genuinely needs connectivity (e.g. cloud
save), and re-justify the permission in the Play Console's data-safety form
if you do.

## Known gaps / roadmap (v0.2+)

This is a complete, playable MVP of the core loop, not a finished product.
Deliberately out of scope for this pass, in rough priority order:

- **Art**: every visual is a placeholder (flat-color icon, default Godot
  theme, no hero portraits/zone backgrounds). This is the single biggest
  thing standing between this build and something you'd actually publish.
- **Per-hero equipment**: crafted items currently grant roster-wide
  percentage bonuses rather than being equipped on individual heroes. A
  real equipment/loadout system is the natural v2 crafting expansion.
- **Combat/battles**: "Warband Power" is tracked as a headline stat, but
  there's no battle screen yet — no boss fights per zone, no stage
  progression tied to a hero's actual combat stats beyond the number going
  up. This is the most natural next system to add given the story's
  chapter structure (one boss/stage per chapter).
- **Sound**: no music or SFX.
- **IAP / ads**: none wired up. The user asked for no monetization
  complexity up front; if you want an ad-supported or IAP model later,
  treat it as a separate, explicit scope addition rather than bolting it
  onto Essence (keep the summon currency earnable-only unless you
  deliberately decide otherwise).
- **Save robustness**: single local save slot, no cloud backup, no save
  migration versioning yet — fine for v0.1, worth adding before a real
  Play Store release so players don't lose progress across devices/reinstalls.
