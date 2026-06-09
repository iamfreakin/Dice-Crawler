class_name BattleManager
extends Node
## 전투 흐름을 상태 머신으로 제어한다.
## DRAW -> PLAYER_TURN -> RESOLVE -> ENEMY_TURN -> REWARD

signal state_changed(new_state: State)
signal hand_drawn(hand: Array)
signal dice_rolled(results: Array)
signal log_message(text: String)
signal battle_ended(victory: bool)

enum State { DRAW, PLAYER_TURN, RESOLVE, ENEMY_TURN, REWARD }

const DRAW_COUNT: int = 5   # 핸드로 뽑는 장수
const MAX_ENERGY: int = 3   # 매 턴 에너지

var _state: State = State.DRAW
var _enemies: Array[EnemyInstance] = []
var target_index: int = 0
var player_block: int = 0
var energy: int = 0

var _draw_pile: Array[DiceData] = []
var _discard_pile: Array[DiceData] = []
var _hand: Array[DiceData] = []
var _rolled: Dictionary = {}  # 핸드 인덱스 -> FaceData (굴린 주사위)


func start_battle(enemy_defs: Array[EnemyData]) -> void:
	_enemies.clear()
	target_index = 0
	for def in enemy_defs:
		_enemies.append(EnemyInstance.new(def))
	_draw_pile = GameManager.dice_pool.duplicate()
	_draw_pile.shuffle()
	_discard_pile.clear()
	GameManager.grant_reroll_tokens(1 + GameManager.relic_value(RelicData.Effect.EXTRA_REROLL))
	_change_state(State.DRAW)


func _change_state(new_state: State) -> void:
	_state = new_state
	state_changed.emit(_state)
	match _state:
		State.DRAW:
			_do_draw()
		State.RESOLVE:
			_do_resolve()
		State.ENEMY_TURN:
			_do_enemy_turn()
		State.PLAYER_TURN, State.REWARD:
			pass


func _do_draw() -> void:
	player_block = GameManager.relic_value(RelicData.Effect.BLOCK_PER_TURN)
	energy = MAX_ENERGY
	_hand.clear()
	_rolled.clear()
	for i in DRAW_COUNT:
		var d := _draw_one()
		if d != null:
			_hand.append(d)
	hand_drawn.emit(_hand)
	_change_state(State.PLAYER_TURN)


func _draw_one() -> DiceData:
	if _draw_pile.is_empty():
		_reshuffle()
	if _draw_pile.is_empty():
		return null
	return _draw_pile.pop_back()


func _reshuffle() -> void:
	_draw_pile = _discard_pile.duplicate()
	_discard_pile.clear()
	_draw_pile.shuffle()


## 핸드 index의 주사위를 굴린다. 에너지가 충분하고 아직 안 굴렸으면 성공.
func roll_index(index: int) -> bool:
	if not can_roll(index):
		return false
	var die: DiceData = _hand[index]
	energy -= die.energy_cost
	_rolled[index] = die.roll()
	dice_rolled.emit(_results())
	return true


func can_roll(index: int) -> bool:
	if index < 0 or index >= _hand.size() or _rolled.has(index):
		return false
	return energy >= (_hand[index] as DiceData).energy_cost


func is_rolled(index: int) -> bool:
	return _rolled.has(index)


func any_rolled() -> bool:
	return not _rolled.is_empty()


func face_for(index: int) -> FaceData:
	return _rolled.get(index)


## 토큰 1개로 이미 굴린 주사위 전부 재굴림.
func reroll() -> bool:
	if _rolled.is_empty():
		return false
	if not GameManager.spend_reroll_token():
		return false
	for i in _rolled.keys():
		_rolled[i] = (_hand[i] as DiceData).roll()
	dice_rolled.emit(_results())
	return true


## 굴린 주사위 결과 목록 {die, face}.
func _results() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in _rolled.keys():
		out.append({"die": _hand[i], "face": _rolled[i]})
	return out


func confirm_turn() -> void:
	_change_state(State.RESOLVE)


func _do_resolve() -> void:
	var damage: int = 0
	var block_gain: int = 0
	var burn_to_apply: int = 0
	var element_counts: Dictionary = {}

	for r in _results():
		var die: DiceData = r["die"]
		var face: FaceData = r["face"]
		match face.kind:
			DiceData.FaceKind.NUMBER:
				if die.dice_type == DiceData.DiceType.DEFENSE:
					block_gain += face.value
				else:
					damage += face.value
			DiceData.FaceKind.FIRE:
				damage += face.value
				burn_to_apply += 2
				element_counts[face.kind] = element_counts.get(face.kind, 0) + 1
			DiceData.FaceKind.ICE, DiceData.FaceKind.LIGHTNING:
				damage += face.value
				element_counts[face.kind] = element_counts.get(face.kind, 0) + 1
			DiceData.FaceKind.CURSE:
				GameManager.grant_reroll_tokens(GameManager.reroll_tokens + 1)
				log_message.emit("저주 면: 리롤 토큰 +1")
			DiceData.FaceKind.REROLL:
				GameManager.grant_reroll_tokens(GameManager.reroll_tokens + 1)
				log_message.emit("리롤 면: 리롤 토큰 +1")

	var target := current_target()

	if element_counts.get(DiceData.FaceKind.FIRE, 0) >= 2:
		burn_to_apply += 3
		log_message.emit("불 시너지: 화상 +3")
	if target != null and element_counts.get(DiceData.FaceKind.ICE, 0) >= 2:
		target.apply_weak(2)
		log_message.emit("얼음 시너지: 약화 2턴")
	if target != null and element_counts.get(DiceData.FaceKind.LIGHTNING, 0) >= 2:
		target.apply_vulnerable(2)
		log_message.emit("번개 시너지: 취약 2턴")

	player_block += block_gain
	if block_gain > 0:
		log_message.emit("방어 +%d (현재 %d)" % [block_gain, player_block])

	if target != null:
		if burn_to_apply > 0:
			burn_to_apply += GameManager.relic_value(RelicData.Effect.BURN_BOOST)
			target.apply_burn(burn_to_apply)
			log_message.emit("%s에게 화상 +%d" % [target.data.display_name, burn_to_apply])
		if damage > 0:
			var dealt := target.effective_damage(damage)
			target.take_damage(damage)
			log_message.emit("%s에게 %d 피해" % [target.data.display_name, dealt])

	for d in _hand:
		_discard_pile.append(d)

	if _all_enemies_dead():
		_win()
	else:
		_change_state(State.ENEMY_TURN)


func _do_enemy_turn() -> void:
	for enemy in _enemies:
		if enemy.is_dead():
			continue
		var burn_dmg := enemy.tick_burn()
		if burn_dmg > 0:
			log_message.emit("%s가 화상으로 %d 피해" % [enemy.data.display_name, burn_dmg])
	if _all_enemies_dead():
		_win()
		return

	for enemy in _enemies:
		if enemy.is_dead():
			continue
		_execute_intent(enemy)
		if GameManager.current_hp <= 0:
			log_message.emit("패배...")
			battle_ended.emit(false)
			return
		enemy.advance_intent()
		enemy.decay_status()
	_change_state(State.DRAW)


func _execute_intent(enemy: EnemyInstance) -> void:
	var intent := enemy.current_intent()
	if intent == null:
		return
	match intent.kind:
		IntentData.IntentKind.CHARGE, IntentData.IntentKind.SNIPE, IntentData.IntentKind.EXPLODE:
			var dmg := enemy.weakened(intent.value)
			_player_take_damage(dmg)
			var weak_note := " (약화)" if enemy.weak > 0 else ""
			log_message.emit("%s 공격: %d 피해%s" % [enemy.data.display_name, dmg, weak_note])
		IntentData.IntentKind.REINFORCE:
			enemy.gain_block(intent.value)
			log_message.emit("%s 방어 +%d" % [enemy.data.display_name, intent.value])
		IntentData.IntentKind.SUMMON:
			log_message.emit("%s가 증원을 시도했다" % enemy.data.display_name)


func _player_take_damage(amount: int) -> void:
	var absorbed: int = min(player_block, amount)
	player_block -= absorbed
	GameManager.take_damage(amount - absorbed)


func _win() -> void:
	_grant_victory_gold()
	log_message.emit("전투 승리!")
	_change_state(State.REWARD)
	battle_ended.emit(true)


func _grant_victory_gold() -> void:
	var total: int = 0
	for e in _enemies:
		match e.data.tier:
			EnemyData.Tier.NORMAL:
				total += randi_range(12, 20)
			EnemyData.Tier.ELITE:
				total += randi_range(30, 45)
			EnemyData.Tier.BOSS:
				total += randi_range(60, 80)
	GameManager.add_gold(total)
	log_message.emit("골드 +%d (보유 %d)" % [total, GameManager.gold])


func current_target() -> EnemyInstance:
	if target_index >= 0 and target_index < _enemies.size():
		var e: EnemyInstance = _enemies[target_index]
		if not e.is_dead():
			return e
	return _first_alive_enemy()


func set_target(index: int) -> void:
	if index >= 0 and index < _enemies.size() and not _enemies[index].is_dead():
		target_index = index


func _first_alive_enemy() -> EnemyInstance:
	for e in _enemies:
		if not e.is_dead():
			return e
	return null


func _all_enemies_dead() -> bool:
	return _first_alive_enemy() == null


func get_state() -> State:
	return _state


func get_enemies() -> Array[EnemyInstance]:
	return _enemies


func get_hand() -> Array[DiceData]:
	return _hand
