class_name BattleManager
extends Node
## 전투 흐름을 명시적 상태머신으로 제어한다.
## DRAW → PLAYER_TURN → RESOLVE → ENEMY_TURN → REWARD
## 씬(Battle.tscn) 표현/입력은 시그널을 구독해 반응한다.

signal state_changed(new_state: State)
signal hand_drawn(hand: Array)        ## 드로우된 핸드 (DiceData 배열)
signal dice_rolled(results: Array)    ## 굴림 결과 (FaceData 배열)
signal turn_resolved
signal battle_ended(victory: bool)

enum State { DRAW, PLAYER_TURN, RESOLVE, ENEMY_TURN, REWARD }

const HAND_SIZE: int = 2  ## 핸드에서 선택해 굴리는 주사위 수

var _state: State = State.DRAW
var _enemies: Array[EnemyData] = []

## 드로우 풀/버린 더미 (StS 카드 구조와 동일: 풀 소진 시 셔플 후 재드로우).
var _draw_pile: Array[DiceData] = []
var _discard_pile: Array[DiceData] = []
var _hand: Array[DiceData] = []
## 이번 턴 선택해 굴린 주사위와 그 결과.
var _selected: Array[DiceData] = []
var _roll_results: Array[FaceData] = []

func start_battle(enemies: Array[EnemyData]) -> void:
	_enemies = enemies
	_draw_pile = GameManager.dice_pool.duplicate()
	_draw_pile.shuffle()
	_discard_pile.clear()
	GameManager.grant_reroll_tokens(1)  # 스테이지당 기본 1개 (유물로 보정 가능)
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
	_hand.clear()
	for i in HAND_SIZE:
		_hand.append(_draw_one())
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
## 플레이어가 핸드에서 주사위를 선택하고 굴린다.
func roll_selected(selection: Array[DiceData]) -> void:
	_selected = selection
	_roll_results.clear()
	for d in _selected:
		_roll_results.append(d.roll())
	dice_rolled.emit(_roll_results)

## 리롤 토큰을 1개 써서 다시 굴린다. 토큰 없으면 false.
func reroll() -> bool:
	if not GameManager.spend_reroll_token():
		return false
	roll_selected(_selected)
	return true

## 플레이어가 결과를 확정하면 RESOLVE 로 진행.
func confirm_turn() -> void:
	_change_state(State.RESOLVE)

# --- RESOLVE ------------------------------------------------------------
func _do_resolve() -> void:
	# TODO: _roll_results 를 적용 (데미지/실드/효과) + 시너지 판정
	#       (같은 속성 면 2개 이상 → 추가 효과)
	_apply_synergies()
	# 사용한 주사위는 버린 더미로
	for d in _hand:
		if d != null:
			_discard_pile.append(d)
	turn_resolved.emit()
	if _all_enemies_dead():
		_change_state(State.REWARD)
	else:
		_change_state(State.ENEMY_TURN)

func _apply_synergies() -> void:
	# TODO: _roll_results 의 FaceData.kind 별 개수를 세어 2개 이상이면 보너스 적용.
	pass

# --- ENEMY_TURN ---------------------------------------------------------
func _do_enemy_turn() -> void:
	# TODO: 각 적의 현재 의도(IntentData)를 실행 → 플레이어에게 적용.
	#       이후 다음 의도로 진행.
	_change_state(State.DRAW)

# --- 종료 판정 ----------------------------------------------------------
func _all_enemies_dead() -> bool:
	# TODO: 적 HP 추적 인스턴스 도입 후 실제 판정으로 교체.
	return false

func get_state() -> State:
	return _state
