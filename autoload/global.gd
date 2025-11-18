extends Node

signal on_create_block_text(unit: Node2D)
signal on_create_damage_text(unit: Node2D, info: HitboxComponent)
signal on_create_heal_text(unit: Node2D, value: float)

signal on_upgrade_selected
signal on_enemy_died(enemy: Enemy)

const FLASH_MATERIAL = preload("uid://br5yx1h5io73o")
const FLOATING_TEXT_SCENE = preload("uid://b6u6hp6ck5aux")

const COMMON_STYLE = preload("uid://dvm50xvp1nb7j")
const EPIC_STYLE = preload("uid://cl1p8hbl57322")
const LEGENDARY_STYLE = preload("uid://bs5fkpq52qfl3")
const RARE_STYLE = preload("uid://b0axckjnxn2h2")

const COINS_SCENE = preload("uid://d2ska12707rk3")
const ITEM_CARD_SCENE = preload("uid://cqd7gxxeb4hju")
const SPAWN_EFFECT_SCENE = preload("uid://beksjf58ejua4")

const UPGRADE_PROBABILITY_CONFIG = {
	"rare" : { "start_wave": 2, "base_mult": 0.06 },
	"epic" : { "start_wave": 4, "base_mult": 0.02 },
	"legendary" : { "start_wave": 7, "base_mult": 0.0023 },
}

const SHOP_PROBABILITY_CONFIG = {
	"rare" : { "start_wave": 2, "base_mult": 0.10 },
	"epic" : { "start_wave": 4, "base_mult": 0.05 },
	"legendary" : { "start_wave": 7, "base_mult": 0.01 },
}

const ECONOMY_CONFIG = {
	"starting_coins": 45,
	"coin_drop_multiplier_start": 0.75,
	"coin_drop_penalty_per_wave": 0.03,
	"coin_drop_multiplier_min": 0.45,
	"shop_price_increase_per_wave": 0.08,
	"shop_price_increase_cap": 1.9,
}

const DIFFICULTY_CONFIG = {
	"player_health_base_multiplier": 0.8,
	"player_health_growth_per_wave": 0.08,
	"player_health_flat_bonus_per_wave": 1.5,
	"player_health_max_multiplier": 2.5,
	"enemy_damage_base_multiplier": 1.0,
	"enemy_damage_wave_growth": 0.15,
	"enemy_damage_max_multiplier": 4.0,
}

const TIER_COLORS: Dictionary[UpgradeTier, Color] = {
	UpgradeTier.RARE: Color(0.0, 0.557, 0.741),
	UpgradeTier.EPIC: Color(0.478, 0.251, 0.71),
	UpgradeTier.LEGENDARY: Color(0.906, 0.212, 0.212)
}

enum UpgradeTier {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

var available_players: Dictionary[String, PackedScene] = {
	"Brawler": preload("uid://d3yi6tnvpsxfo"),
	"Bunny": preload("uid://bm1gv88kpq8df"),
	"Crazy": preload("uid://xgep30mgy4iv"),
	"Knight": preload("uid://cxo7j15umxys6"),
	"Well Rounded": preload("uid://ylarq2r0auqf"),
}

var coins: int = ECONOMY_CONFIG.starting_coins
var player: Player
var game_paused: bool

var main_player_selected: UnitStats
var main_weapon_selected: ItemWeapon

var selected_weapon: ItemWeapon
var equipped_weapons: Array[ItemWeapon]

func get_harvesting_coins() -> void:
	coins += player.stats.harvesting


func get_selected_player() -> Player:
	var player_path: PackedScene = available_players[main_player_selected.name]
	var player_instance := player_path.instantiate()
	ensure_stats_baseline(player_instance.stats)
	player_instance.stats.health = get_player_health_for_wave(player_instance.stats, 1)
	player = player_instance
	return player


func get_chance_sucess(chance: float) -> bool:
	var random := randf_range(0, 1)
	if random < chance:
		return true
	return false


func get_tier_style(tier: UpgradeTier) -> StyleBoxFlat:
	match tier:
		UpgradeTier.COMMON:
			return COMMON_STYLE
		UpgradeTier.RARE:
			return RARE_STYLE
		UpgradeTier.EPIC:
			return EPIC_STYLE
		_:
			return LEGENDARY_STYLE


func calculate_tier_probability(current_wave: int, config: Dictionary) -> Array[float]:
	var common_chance := 0.0
	var rare_chance := 0.0
	var epic_chance := 0.0
	var legendary_chance := 0.0
	
	# RARE
	if current_wave >= config.rare.start_wave:
		rare_chance = min(1.0, (current_wave - 1) * config.rare.base_mult)
	
	# EPIC
	if current_wave >= config.epic.start_wave:
		epic_chance = min(1.0, (current_wave - 3) * config.epic.base_mult)
	
	# LEGENDARY
	if current_wave >= config.legendary.start_wave:
		legendary_chance = min(1.0, (current_wave - 6) * config.legendary.base_mult)
	
	# LUCK
	# Player -> Luck 10 -> 10% chance -> 1.1 Mult
	var luck_factor := 1.0 + (Global.player.stats.luck / 100.0)
	rare_chance *= luck_factor
	epic_chance *= luck_factor
	legendary_chance *= luck_factor
	
	# Normalize probabilities
	var total_non_common_chance := rare_chance + epic_chance + legendary_chance
	if total_non_common_chance > 1.0:
		var scale_down := 1.0 / total_non_common_chance
		rare_chance *= scale_down
		epic_chance *= scale_down
		legendary_chance *= scale_down
		total_non_common_chance = 1.0
	
	common_chance = 1.0 - total_non_common_chance
	
	print("Wave: %d, Luck: %.1f => Chances C:%.2f R:%.2f E:%.2f L:%.2f" %
	[current_wave, Global.player.stats.luck, common_chance, rare_chance, epic_chance, legendary_chance])
	
	return [
		max(0.0, common_chance),
		max(0.0, rare_chance),
		max(0.0, epic_chance),
		max(0.0, legendary_chance)
	]


func select_items_for_offer(item_pool: Array, current_wave: int, config: Dictionary) -> Array:
	var tier_chances: Array[float] = calculate_tier_probability(current_wave, config)
	
	var legendary_limit := tier_chances[3]
	var epic_limit := legendary_limit + tier_chances[2]
	var rare_limit := epic_limit + tier_chances[1]
	
	var offered_items: Array = []
	
	while offered_items.size() < 4:
		var roll := randf()
		var chosen_tier_index := 0
		if roll < legendary_limit:
			chosen_tier_index = 3 # Legendary
		elif roll < epic_limit:
			chosen_tier_index = 2 # Epic
		elif roll < rare_limit:
			chosen_tier_index = 1 # Rare
		
		var potential_items: Array = []
		var current_search_tier_index := chosen_tier_index
		
		while potential_items.is_empty() and current_search_tier_index >= 0:
			potential_items = item_pool.filter(func(item: ItemBase): return item.item_tier == current_search_tier_index)
			
			if potential_items.is_empty():
				current_search_tier_index -= 1
			else:
				break
		
		if not potential_items.is_empty():
			var random_item = potential_items.pick_random()
			
			if not offered_items.has(random_item):
				offered_items.append(random_item)
	
	return offered_items


func reset_run_state() -> void:
	if is_instance_valid(player):
		player.queue_free()
	player = null
	game_paused = false
	main_player_selected = null
	main_weapon_selected = null
	selected_weapon = null
	equipped_weapons.clear()
	coins = ECONOMY_CONFIG.starting_coins


func get_price_multiplier_for_wave(wave: int) -> float:
	var safe_wave: int = max(1, wave)
	var growth: float = float(safe_wave - 1) * ECONOMY_CONFIG.shop_price_increase_per_wave
	return min(1.0 + growth, ECONOMY_CONFIG.shop_price_increase_cap)


func get_price_for_wave(base_cost: int, wave: int) -> int:
	var multiplier: float = get_price_multiplier_for_wave(wave)
	var adjusted_cost := int(round(float(base_cost) * multiplier))
	return max(1, adjusted_cost)


func get_coin_drop_for_wave(base_value: int, wave: int) -> int:
	var safe_wave: int = max(1, wave)
	var multiplier: float = ECONOMY_CONFIG.coin_drop_multiplier_start
	multiplier -= float(safe_wave - 1) * ECONOMY_CONFIG.coin_drop_penalty_per_wave
	multiplier = clamp(
		multiplier,
		ECONOMY_CONFIG.coin_drop_multiplier_min,
		ECONOMY_CONFIG.coin_drop_multiplier_start
	)
	var adjusted_value := int(round(float(base_value) * multiplier))
	return max(1, adjusted_value)


func ensure_stats_baseline(stats: UnitStats) -> void:
	if not stats:
		return
	if not stats.has_meta("_base_health"):
		stats.set_meta("_base_health", stats.health)
	if not stats.has_meta("_base_damage"):
		stats.set_meta("_base_damage", stats.damage)


func get_player_health_for_wave(stats: UnitStats, wave: int) -> float:
	ensure_stats_baseline(stats)
	var base_health: float = float(stats.get_meta("_base_health"))
	var safe_wave: int = max(1, wave)
	var multiplier: float = DIFFICULTY_CONFIG.player_health_base_multiplier + float(safe_wave - 1) * DIFFICULTY_CONFIG.player_health_growth_per_wave
	multiplier = clamp(multiplier, DIFFICULTY_CONFIG.player_health_base_multiplier, DIFFICULTY_CONFIG.player_health_max_multiplier)
	var flat_bonus: float = float(safe_wave - 1) * DIFFICULTY_CONFIG.player_health_flat_bonus_per_wave
	return max(1.0, base_health * multiplier + flat_bonus)


func get_enemy_damage_for_wave(stats: UnitStats, wave: int) -> float:
	ensure_stats_baseline(stats)
	var base_damage: float = float(stats.get_meta("_base_damage"))
	var safe_wave: int = max(1, wave)
	var multiplier: float = DIFFICULTY_CONFIG.enemy_damage_base_multiplier + float(safe_wave - 1) * DIFFICULTY_CONFIG.enemy_damage_wave_growth
	multiplier = min(multiplier, DIFFICULTY_CONFIG.enemy_damage_max_multiplier)
	return max(1.0, base_damage * multiplier)


func apply_enemy_wave_scaling(stats: UnitStats, wave: int) -> void:
	if not stats:
		return
	stats.damage = get_enemy_damage_for_wave(stats, wave)
