class_name AnimatedSurface
extends Resource
## One map material that moves on its own (lava, fire, embers): its texture
## scrolls and its brightness flickers. Cheap stand-in for animated
## textures: two material properties set per frame, shared by every brush.

@export var material: StandardMaterial3D
## Texture repeats per second along U and V. Negative V scrolls upward.
@export var scroll: Vector2 = Vector2.ZERO
## Texels per texture side. Scrolling snaps to whole texels so it stays as
## crisp as the textures. 0 scrolls smoothly.
@export var texels: int = 64
## How far brightness dips below full (0 = steady, 0.3 = strong flicker).
@export_range(0.0, 1.0) var flicker_amount: float = 0.0
## Flicker cycles per second.
@export var flicker_speed: float = 1.0
