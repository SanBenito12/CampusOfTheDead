extends Node2D
class_name Spawner

signal on_wave_completed

@export var spawn_area_size := Vector2(1000, 500)
@export var waves_data: Array[WaveData]
@export var enemy_collection: Array[UnitStats]

@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer

var wave_index := 1
var current_wave_data: WaveData
var spawned_enemies: Array[Enemy] = []
var wave_active := false
var is_wave_paused := false
var wave_timer_remaining := 0.0
var spawn_timer_remaining := 0.0
var spawn_timer_was_running := false

func _ready() -> void:
	for stats: UnitStats in enemy_collection:
		Global.ensure_stats_baseline(stats)
		if wave_index == 1:
			Global.apply_enemy_wave_scaling(stats, wave_index)


func find_wave_data() -> WaveData:
	for wave: WaveData in waves_data:
		if wave and wave.is_valid_index(wave_index):
			return wave
	return null

func start_wave() -> void:
	for stats: UnitStats in enemy_collection:
		Global.apply_enemy_wave_scaling(stats, wave_index)
	current_wave_data = find_wave_data()
	if not current_wave_data:
		printerr("No valid wave.")
		spawn_timer.stop()
		wave_timer.stop()
		wave_active = false
		return
	
	wave_active = true
	is_wave_paused = false
	wave_timer_remaining = 0.0
	spawn_timer_remaining = 0.0
	spawn_timer_was_running = false
	
	wave_timer.wait_time = current_wave_data.wave_time
	wave_timer.start()
	
	start_spawn_timer()

func start_spawn_timer() -> void:
	match current_wave_data.spawn_type:
		WaveData.SpawnType.FIXED:
			spawn_timer.wait_time = current_wave_data.fixed_spawn_time
		WaveData.SpawnType.RANDOM:
			var min_t := current_wave_data.min_spawn_time
			var max_t := current_wave_data.max_spawn_time
			spawn_timer.wait_time = randf_range(min_t, max_t)
	
	if spawn_timer.is_stopped():
		spawn_timer.start()


func get_random_spawn_position() -> Vector2:
	var random_x := randf_range(-spawn_area_size.x, spawn_area_size.x)
	var random_y := randf_range(-spawn_area_size.y, spawn_area_size.y)
	return Vector2(random_x, random_y)


func spawn_enemy() -> void:
	var enemy_scene := current_wave_data.get_random_unit_scene() as PackedScene
	if enemy_scene:
		var spawn_pos := get_random_spawn_position()
		
		var spawn_effect := Global.SPAWN_EFFECT_SCENE.instantiate()
		get_parent().add_child(spawn_effect)
		spawn_effect.global_position = spawn_pos
		await spawn_effect.anim_player.animation_finished
		spawn_effect.queue_free()
		
		var instance := enemy_scene.instantiate() as Enemy
		Global.apply_enemy_wave_scaling(instance.stats, wave_index)
		instance.global_position = spawn_pos
		get_parent().add_child(instance)
		spawned_enemies.append(instance)
	
	start_spawn_timer()


func clear_enemies() -> void:
	if spawned_enemies.size() > 0:
		for enemy: Enemy in spawned_enemies:
			if is_instance_valid(enemy):
				enemy.destroy_enemy()
	
	spawned_enemies.clear()


func update_enemies_new_wave() -> void:
	var next_wave := wave_index + 1
	for stats: UnitStats in enemy_collection:
		Global.apply_enemy_wave_scaling(stats, next_wave)


func get_wave_timer_text() -> String:
	return str(int(wave_timer.time_left))


func get_wave_text() -> String:
	return "Wave %d" % wave_index


func _on_spawn_timer_timeout() -> void:
	if not current_wave_data or wave_timer.is_stopped():
		spawn_timer.stop()
		return
	
	spawn_enemy()


func _on_wave_timer_timeout() -> void:
	Global.game_paused = true
	on_wave_completed.emit()
	spawn_timer.stop()
	clear_enemies()
	update_enemies_new_wave()
	wave_active = false
	is_wave_paused = false


func pause_wave() -> void:
	if not wave_active or is_wave_paused:
		return
	
	wave_timer_remaining = wave_timer.time_left
	spawn_timer_was_running = not spawn_timer.is_stopped()
	spawn_timer_remaining = spawn_timer.time_left if spawn_timer_was_running else 0.0
	
	wave_timer.stop()
	if spawn_timer_was_running:
		spawn_timer.stop()
	
	is_wave_paused = true


func resume_wave() -> void:
	if not wave_active or not is_wave_paused:
		return
	
	if wave_timer_remaining > 0.0:
		wave_timer.start(wave_timer_remaining)
	else:
		wave_timer.start()
	
	if spawn_timer_was_running:
		if spawn_timer_remaining > 0.0:
			spawn_timer.start(spawn_timer_remaining)
		else:
			start_spawn_timer()
	
	is_wave_paused = false


func is_wave_running() -> bool:
	return wave_active
