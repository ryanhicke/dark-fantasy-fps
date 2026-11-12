class_name EnemySpriteSheet
extends Resource
## Frame layout for one enemy's sprite sheet: a grid of equal frames, plus
## which frame indices (row-major, starting at 0) each animation uses.
## Read by EnemySprite; enemies without one keep the flat placeholder quad.

@export var texture: Texture2D
@export var columns: int = 4
@export var rows: int = 4

@export_group("Animations")
@export var idle_frames: PackedInt32Array = PackedInt32Array([0])
@export var walk_frames: PackedInt32Array = PackedInt32Array([0])
@export var windup_frames: PackedInt32Array = PackedInt32Array([0])
@export var attack_frames: PackedInt32Array = PackedInt32Array([0])
@export var pain_frames: PackedInt32Array = PackedInt32Array([0])
## Played once on death; the last frame is the corpse.
@export var death_frames: PackedInt32Array = PackedInt32Array([0])
@export var walk_fps: float = 8.0
@export var death_fps: float = 8.0
