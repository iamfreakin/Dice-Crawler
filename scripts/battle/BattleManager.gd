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
var _context: RollContext = RollContext.new()  # 이번 턴 굴림 이벤트 로그
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()  # Combat 시드 RNG


func start_battle(enemy_defs: Array[EnemyData]) -> void:
	_enemies.clear()
	target_index = 0
	_rng.randomize()
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
	_context.clear()
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


## 핸드 index의 주사위를 즉시 굴린다 (에너지 소모). 적응형: 하나씩 보고 다음을 결정.
func roll_index(index: int) -> bool:
	if not can_roll(index):
		return false
	var die: DiceData = _hand[index]
	energy -= die.energy_cost
	_context.add(RollEntry.new(index, die, _rng.randf()))
	dice_rolled.emit(_results())
	return true


func can_roll(index: int) -> bool:
	if index < 0 or index >= _hand.size() or _context.has_index(index):
		return false
	return energy >= (_hand[index] as DiceData).energy_cost


func cost_of(index: int) -> int:
	if index < 0 or index >= _hand.size():
		return 0
	return (_hand[index] as DiceData).energy_cost


func is_rolled(index: int) -> bool:
	return _context.has_index(index)


func any_rolled() -> bool:
	return not _context.is_empty()


func face_for(index: int) -> FaceData:
	var e := _context.get_entry(index)
	return e.base_face if e != null else null


## 토큰 1개로 굴린 주사위 하나만 재굴림 (해당 항목의 rng_token 재발급 → 재선택).
func reroll_index(index: int) -> bool:
	var e := _context.get_entry(index)
	if e == null:
		return false
	if not GameManager.spend_reroll_token():
		return false
	e.reissue(_rng.randf())
	dice_rolled.emit(_results())
	return true


## 굴린 주사위 결과 목록 {die, face} (UI/시그널용).
func _results() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _context.entries:
		out.append({"die": e.die, "face": e.base_face})
	return out


func confirm_turn() -> void:
	_change_state(State.RESOLVE)


func _do_resolve() -> void:
	var target := current_target()
	var outcome := _compute_outcome(target)
	_apply_outcome(outcome, target)

	for d in _hand:
		_discard_pile.append(d)

	if _all_enemies_dead():
		_win()
	else:
		_change_state(State.ENEMY_TURN)


## 순수 정산: RollContext를 해석해 BattleOutcome 계산 (게임 상태 변경 없음).
## 미리보기와 실제 적용이 이 함수를 공유한다.
func _compute_outcome(target: EnemyInstance) -> BattleOutcome:
	var o := BattleOutcome.new()
	var counts: Dictionary = {}
	for e in _context.entries:
		var die: DiceData = e.die
		var face: FaceData = e.base_face
		match face.kind:
			DiceData.FaceKind.NUMBER:
				if die.dice_type == DiceData.DiceType.DEFENSE:
					o.block += face.value
				else:
					o.damage += face.value
			DiceData.FaceKind.FIRE:
				o.damage += face.value
				o.burn += 2
				counts[face.kind] = counts.get(face.kind, 0) + 1
			DiceData.FaceKind.ICE, DiceData.FaceKind.LIGHTNING:
				o.damage += face.value
				counts[face.kind] = counts.get(face.kind, 0) + 1
			DiceData.FaceKind.CURSE:
				o.token_gain += 1
				o.logs.append("저주 면: 리롤 토큰 +1")
			DiceData.FaceKind.REROLL:
				o.token_gain += 1
				o.logs.append("리롤 면: 리롤 토큰 +1")

	# 시너지 (같은 속성 2개 이상)
	if counts.get(DiceData.FaceKind.FIRE, 0) >= 2:
		o.burn += 3
		o.logs.append("불 시너지: 화상 +3")
	if counts.get(DiceData.FaceKind.ICE, 0) >= 2:
		o.apply_weak = 2
		o.logs.append("얼음 시너지: 약화 2턴")
	if counts.get(DiceData.FaceKind.LIGHTNING, 0) >= 2:
		o.apply_vulnerable = 2
		o.logs.append("번개 시너지: 취약 2턴")

	# 유물: 화상 부여 시 강화
	if o.burn > 0:
		o.burn += GameManager.relic_value(RelicData.Effect.BURN_BOOST)

	# 취약 반영 실제 피해 (이미 취약이거나 이번 턴 취약 부여 시 증폭) — 표시/미리보기용
	var will_vuln: bool = (target != null and target.vulnerable > 0) or o.apply_vulnerable > 0
	o.dealt = int(round(o.damage * EnemyInstance.VULNERABLE_MULT)) if will_vuln else o.damage

	return o


## 미리보기: 적용하지 않고 현재 타겟 기준 정산값만 반환 (Phase 2 예상 피해 표시용).
func preview() -> BattleOutcome:
	return _compute_outcome(current_target())


## BattleOutcome을 실제 게임 상태에 적용 (확정 시 1회).
func _apply_outcome(o: BattleOutcome, target: EnemyInstance) -> void:
	for line in o.logs:
		log_message.emit(line)
	if o.token_gain > 0:
		GameManager.grant_reroll_tokens(GameManager.reroll_tokens + o.token_gain)
	player_block += o.block
	if o.block > 0:
		log_message.emit("방어 +%d (현재 %d)" % [o.block, player_block])
	if target != null:
		if o.apply_weak > 0:
			target.apply_weak(o.apply_weak)
		if o.apply_vulnerable > 0:
			target.apply_vulnerable(o.apply_vulnerable)
		if o.burn > 0:
			target.apply_burn(o.burn)
			log_message.emit("%s에게 화상 +%d" % [target.data.display_name, o.burn])
		if o.damage > 0:
			var dealt := target.effective_damage(o.damage)
			target.take_damage(o.damage)
			log_message.emit("%s에게 %d 피해" % [target.data.display_name, dealt])


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
