class_name BattleManager
extends Node
## 전투 흐름을 명시적 상태머신으로 제어한다.
## DRAW → PLAYER_TURN → RESOLVE → ENEMY_TURN → REWARD
## 표현/입력(BattleScreen)은 시그널을 구독해 반응한다.

signal state_changed(new_state: State)
signal hand_drawn(hand: Array)          ## 드로우된 핸드 (DiceData 배열)
signal dice_rolled(results: Array)      ## 굴림 결과 [{die, face}, ...]
signal log_message(text: String)        ## 화면 로그용 메시지
signal battle_ended(victory: bool)

enum State { DRAW, PLAYER_TURN, RESOLVE, ENEMY_TURN, REWARD }

const HAND_SIZE: int = 3  ## 핸드에서 선택해 굴리는 주사위 수

var _state: State = State.DRAW
var _enemies: Array[EnemyInstance] = []
var player_block: int = 0

## 드로우 풀/버린 더미 (StS 카드 구조: 풀 소진 시 셔플 후 재드로우).
var _draw_pile: Array[DiceData] = []
var _discard_pile: Array[DiceData] = []
var _hand: Array[DiceData] = []
## 이번 턴 굴린 결과. 각 항목 = {die: DiceData, face: FaceData}
var _roll_results: Array[Dictionary] = []

func start_battle(enemy_defs: Array[EnemyData]) -> void:
	_enemies.clear()
	for def in enemy_defs:
		_enemies.append(EnemyInstance.new(def))
	_draw_pile = GameManager.dice_pool.duplicate()
	_draw_pile.shuffle()
	_discard_pile.clear()
	# 스테이지당 기본 1개 + 유물 보정
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
			pass  # 입력/표현 레이어가 처리

# --- DRAW ---------------------------------------------------------------
func _do_draw() -> void:
	# 방어는 매 턴 초기화. 유물(매 턴 방어)이 있으면 그만큼 시작 방어 부여.
	player_block = GameManager.relic_value(RelicData.Effect.BLOCK_PER_TURN)
	_hand.clear()
	_roll_results.clear()
	for i in HAND_SIZE:
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

# --- PLAYER_TURN (입력 레이어가 호출) -----------------------------------
## 현재 핸드 전체를 굴린다.
func roll_hand() -> void:
	_roll_results.clear()
	for d in _hand:
		_roll_results.append({"die": d, "face": d.roll()})
	dice_rolled.emit(_roll_results)

## 리롤 토큰 1개를 써서 다시 굴린다. 토큰 없으면 false.
func reroll() -> bool:
	if not GameManager.spend_reroll_token():
		return false
	roll_hand()
	return true

## 결과 확정 → RESOLVE 진행. 아직 안 굴렸으면 무시.
func confirm_turn() -> void:
	if _roll_results.is_empty():
		return
	_change_state(State.RESOLVE)

# --- RESOLVE ------------------------------------------------------------
func _do_resolve() -> void:
	var damage: int = 0
	var block_gain: int = 0
	var burn_to_apply: int = 0
	var element_counts: Dictionary = {}  # FaceKind -> count

	for r in _roll_results:
		var die: DiceData = r["die"]
		var face: FaceData = r["face"]
		match face.kind:
			DiceData.FaceKind.NUMBER:
				if die.dice_type == DiceData.DiceType.DEFENSE:
					block_gain += face.value
				else:
					damage += face.value  # ATTACK / SKILL 숫자 면
			DiceData.FaceKind.FIRE:
				damage += face.value
				burn_to_apply += 2  # 🔥 화상 부여
				element_counts[face.kind] = element_counts.get(face.kind, 0) + 1
			DiceData.FaceKind.ICE, DiceData.FaceKind.LIGHTNING:
				damage += face.value
				element_counts[face.kind] = element_counts.get(face.kind, 0) + 1
			DiceData.FaceKind.CURSE:
				GameManager.grant_reroll_tokens(GameManager.reroll_tokens + 1)
				log_message.emit("💀 저주 면 — 리롤 토큰 +1")
			DiceData.FaceKind.REROLL:
				GameManager.grant_reroll_tokens(GameManager.reroll_tokens + 1)
				log_message.emit("🔄 리롤 토큰 +1")

	var target := _first_alive_enemy()

	# 속성별 시너지 (같은 속성 2개 이상)
	if element_counts.get(DiceData.FaceKind.FIRE, 0) >= 2:
		burn_to_apply += 3
		log_message.emit("🔥🔥 시너지 — 화상 강화 (+3)")
	if target != null and element_counts.get(DiceData.FaceKind.ICE, 0) >= 2:
		target.apply_weak(2)
		log_message.emit("❄️❄️ 시너지 — 적 약화 2턴")
	if target != null and element_counts.get(DiceData.FaceKind.LIGHTNING, 0) >= 2:
		target.apply_vulnerable(2)
		log_message.emit("⚡⚡ 시너지 — 적 취약 2턴")

	# 방어 적용
	player_block += block_gain
	if block_gain > 0:
		log_message.emit("🛡️ 방어 +%d (현재 %d)" % [block_gain, player_block])

	# 적에게 효과/데미지 적용 (취약은 take_damage 내부에서 반영)
	if target != null:
		if burn_to_apply > 0:
			burn_to_apply += GameManager.relic_value(RelicData.Effect.BURN_BOOST)
			target.apply_burn(burn_to_apply)
			log_message.emit("🔥 %s 에게 화상 +%d" % [target.data.display_name, burn_to_apply])
		if damage > 0:
			var dealt := target.effective_damage(damage)
			target.take_damage(damage)
			log_message.emit("⚔️ %s 에게 %d 데미지" % [target.data.display_name, dealt])

	# 사용한 핸드는 버린 더미로
	for d in _hand:
		_discard_pile.append(d)

	if _all_enemies_dead():
		log_message.emit("🎉 전투 승리!")
		_change_state(State.REWARD)
		battle_ended.emit(true)
	else:
		_change_state(State.ENEMY_TURN)

# --- ENEMY_TURN ---------------------------------------------------------
func _do_enemy_turn() -> void:
	# 1) 화상 등 턴 시작 상태 처리
	for enemy in _enemies:
		if enemy.is_dead():
			continue
		var burn_dmg := enemy.tick_burn()
		if burn_dmg > 0:
			log_message.emit("🔥 %s 이(가) 화상으로 %d 피해" % [enemy.data.display_name, burn_dmg])
	if _all_enemies_dead():
		log_message.emit("🎉 전투 승리! (화상)")
		_change_state(State.REWARD)
		battle_ended.emit(true)
		return

	# 2) 적 행동
	for enemy in _enemies:
		if enemy.is_dead():
			continue
		_execute_intent(enemy)
		if GameManager.current_hp <= 0:
			log_message.emit("💀 패배...")
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
			var dmg := enemy.weakened(intent.value)  # 약화 시 공격력 감소
			_player_take_damage(dmg)
			var weak_note := " (약화)" if enemy.weak > 0 else ""
			log_message.emit("%s 의 공격 — %d 데미지%s" % [enemy.data.display_name, dmg, weak_note])
		IntentData.IntentKind.REINFORCE:
			enemy.gain_block(intent.value)
			log_message.emit("%s 가 방어 +%d" % [enemy.data.display_name, intent.value])
		IntentData.IntentKind.SUMMON:
			log_message.emit("%s 가 증원을 시도했다 (미구현)" % enemy.data.display_name)

func _player_take_damage(amount: int) -> void:
	var absorbed: int = min(player_block, amount)
	player_block -= absorbed
	GameManager.take_damage(amount - absorbed)

# --- 조회 --------------------------------------------------------------
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
