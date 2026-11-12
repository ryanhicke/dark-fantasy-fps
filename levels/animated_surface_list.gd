class_name AnimatedSurfaceList
extends Resource
## Every map material that animates. One shared list: materials not used by
## a level cost nothing but a property set per frame.

@export var surfaces: Array[AnimatedSurface] = []
