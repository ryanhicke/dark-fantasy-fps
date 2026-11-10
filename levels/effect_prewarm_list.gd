class_name EffectPrewarmList
extends Resource
## Effect scenes whose shaders are compiled during level load (see
## EffectPrewarmer). Add any projectile or effect scene that hitches the
## first time it appears.

@export var scenes: Array[PackedScene] = []
