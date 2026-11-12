class_name GameSounds
extends Resource
## Sounds shared across the whole game: world objects, pickups, menus, and
## HUD events. One file to fill in (core/game_sounds.tres), loaded by
## AudioManager as AudioManager.sounds.
##
## These live here rather than on each object because doors and exits are
## TrenchBroom brushes built by FuncGodot, which have no scene to put
## sounds on. Pickups can still override theirs per scene (Pickup.pickup_sound).
## Every slot may be empty; an empty slot is silent.

@export_group("Pickups")
@export var weapon_pickup: AudioStream
@export var ammo_pickup: AudioStream
@export var health_pickup: AudioStream
@export var key_pickup: AudioStream

@export_group("Doors and Levers")
## Played at the door as it starts to open (also when it reopens for
## someone standing in the doorway).
@export var door_open: AudioStream
@export var door_close: AudioStream
## Using a door you lack the key for.
@export var door_locked: AudioStream
@export var lever_pull: AudioStream

@export_group("Exits")
## A boss exit appearing as a portal once the boss dies.
@export var portal_open: AudioStream
## Walking into the exit. Plays over the intermission screen.
@export var level_exit: AudioStream
## Played when the player enters a hidden area (trigger_secret).
@export var secret_found: AudioStream

@export_group("Crystal Obelisks")
@export var obelisk_shatter: AudioStream
## A hit from the wrong weapon, which does nothing.
@export var obelisk_clink: AudioStream

@export_group("Player")
## The armor spell is about to wear off (when the gold tint starts blinking).
@export var armor_fading: AudioStream

@export_group("Menus")
## Moving the highlight, or stepping a volume row.
@export var menu_move: AudioStream
@export var menu_select: AudioStream
## The Back row.
@export var menu_back: AudioStream
## Confirming the intermission screen.
@export var intermission_continue: AudioStream
