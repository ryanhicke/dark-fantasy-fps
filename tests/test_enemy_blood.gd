extends GutTest
## Blood sprays use the enemy's color, and a clear color sprays nothing.


func test_blood_takes_the_color() -> void:
	var blood: EnemyBlood = EnemyBlood.create(Color.RED)
	add_child_autofree(blood)
	assert_true(blood.visible)
	blood.spray_hit()
	assert_true(blood.emitting)


func test_clear_color_sprays_nothing() -> void:
	var blood: EnemyBlood = EnemyBlood.create(Color(0.0, 0.0, 0.0, 0.0))
	add_child_autofree(blood)
	blood.spray_death()
	assert_false(blood.emitting)


func test_skeletons_shed_pale_dust() -> void:
	var data: EnemyData = load("res://enemies/skeleton/skeleton.tres") as EnemyData
	assert_gt(data.blood_color.r, 0.6, "bone dust, not red blood")
