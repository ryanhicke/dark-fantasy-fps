extends GutTest

const MAX_HEALTH: float = 100.0

var _health: HealthComponent


func before_each() -> void:
	_health = HealthComponent.new()
	_health.max_health = MAX_HEALTH
	add_child_autofree(_health)
	watch_signals(_health)


func test_starts_at_max_health() -> void:
	assert_eq(_health.current_health, MAX_HEALTH)
	assert_false(_health.is_dead())


func test_damage_reduces_health() -> void:
	_health.take_damage(25.0, Damage.Type.PHYSICAL, null)
	assert_eq(_health.current_health, 75.0)


func test_damaged_signal_reports_amount_and_type() -> void:
	_health.take_damage(25.0, Damage.Type.FIRE, null)
	assert_signal_emitted_with_parameters(_health, "damaged", [25.0, Damage.Type.FIRE, null])
	assert_signal_emitted_with_parameters(_health, "health_changed", [75.0, MAX_HEALTH])


func test_overkill_clamps_to_zero_and_reports_applied_amount() -> void:
	_health.take_damage(250.0, Damage.Type.PHYSICAL, null)
	assert_eq(_health.current_health, 0.0)
	assert_true(_health.is_dead())
	assert_signal_emitted_with_parameters(_health, "damaged", [MAX_HEALTH, Damage.Type.PHYSICAL, null])


func test_died_emits_exactly_once() -> void:
	_health.take_damage(100.0, Damage.Type.PHYSICAL, null)
	_health.take_damage(50.0, Damage.Type.PHYSICAL, null)
	assert_signal_emit_count(_health, "died", 1)


func test_damage_after_death_is_ignored() -> void:
	_health.take_damage(100.0, Damage.Type.PHYSICAL, null)
	_health.take_damage(50.0, Damage.Type.PHYSICAL, null)
	assert_eq(_health.current_health, 0.0)
	assert_signal_emit_count(_health, "damaged", 1)


func test_zero_and_negative_damage_are_ignored() -> void:
	_health.take_damage(0.0, Damage.Type.PHYSICAL, null)
	_health.take_damage(-10.0, Damage.Type.PHYSICAL, null)
	assert_eq(_health.current_health, MAX_HEALTH)
	assert_signal_not_emitted(_health, "damaged")


func test_reset_restores_health_and_allows_damage_again() -> void:
	_health.take_damage(100.0, Damage.Type.PHYSICAL, null)
	_health.reset()
	assert_eq(_health.current_health, MAX_HEALTH)
	assert_false(_health.is_dead())
	_health.take_damage(10.0, Damage.Type.PHYSICAL, null)
	assert_eq(_health.current_health, 90.0)


func test_find_on_returns_component_or_null() -> void:
	var target: Node = Node.new()
	add_child_autofree(target)
	assert_null(HealthComponent.find_on(target))
	assert_null(HealthComponent.find_on(null))

	var component: HealthComponent = HealthComponent.new()
	component.name = HealthComponent.NODE_NAME
	target.add_child(component)
	assert_eq(HealthComponent.find_on(target), component)


func test_set_health_clamps_and_never_counts_as_damage() -> void:
	_health.set_health(40.0)
	assert_eq(_health.current_health, 40.0)
	assert_signal_emitted_with_parameters(_health, "health_changed", [40.0, MAX_HEALTH])
	_health.set_health(MAX_HEALTH + 10.0)
	assert_eq(_health.current_health, MAX_HEALTH)
	assert_signal_not_emitted(_health, "damaged")
	assert_signal_not_emitted(_health, "died")
