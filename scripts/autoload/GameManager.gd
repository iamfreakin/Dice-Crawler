extends Node
## 런(run) 전역 상태 관리 Autoload 싱글톤.
## project.godot 에 Autoload 이름 "GameManager" 로 등록한다.
## 씬 간 직접 참조 대신 이 매니저와 시그널을 경유해 상태를 공유한다.

signal hp_changed(current: int, max: int)
signal floor_changed(floor: int)
signal reroll_tokens_changed(amount: int)
signal gold_changed(amount: int)
signal run_started
signal run_ended(victory: bool)

## --- 플레이어 런 상태 ---
var max_hp: int = 50
var current_hp: int = 50
var current_floor: int = 0
var gold: int = 0

## 주사위 풀(덱). 전투 시 여기서 드로우한다.
var dice_pool: Array[DiceData] = []
## 보유 유물.
var relics: Array[RelicData] = []

## 스테이지당 리롤 토큰 (미사용 시 소멸, 이월 없음).
var reroll_tokens: int = 0

## --- 노드 맵 상태 ---
var map: Array = []              ## Array[Array[MapNode]]
var current_node: MapNode = null ## 플레이어가 현재 위치한 노드 (null = 시작 전)

func start_new_run() -> void:
	current_hp = max_hp
	current_floor = 0
	gold = 0
	dice_pool.clear()
	relics.clear()
	reroll_tokens = 0
	current_node = null
	_grant_starting_dice()
	map = MapGenerator.generate()
	run_started.emit()

# --- 골드 --------------------------------------------------------------
func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

# --- 맵 이동 ------------------------------------------------------------
## 현재 위치에서 이동 가능한 다음 노드들.
func get_available_nodes() -> Array[MapNode]:
	var result: Array[MapNode] = []
	if current_node == null:
		if not map.is_empty():
			for n in map[0]:
				result.append(n)
	else:
		for nid in current_node.next:
			var n := find_node(nid)
			if n != null:
				result.append(n)
	return result

func find_node(node_id: int) -> MapNode:
	for row in map:
		for n in row:
			if n.id == node_id:
				return n
	return null

func move_to(node: MapNode) -> void:
	current_node = node
	current_floor = node.row + 1
	floor_changed.emit(current_floor)

func is_at_boss() -> bool:
	return current_node != null and current_node.type == MapNode.Type.BOSS

# --- 유물 ---------------------------------------------------------------
## 유물 획득. 즉시 효과(최대 HP 증가 등)는 여기서 적용.
func add_relic(relic: RelicData) -> void:
	relics.append(relic)
	if relic.effect == RelicData.Effect.MAX_HP_UP:
		max_hp += relic.value
		current_hp += relic.value
		hp_changed.emit(current_hp, max_hp)

func has_relic(relic_id: StringName) -> bool:
	for r in relics:
		if r.id == relic_id:
			return true
	return false

## 특정 효과를 가진 유물들의 value 합 (전투 훅에서 사용).
func relic_value(effect: RelicData.Effect) -> int:
	var total: int = 0
	for r in relics:
		if r.effect == effect:
			total += r.value
	return total

## 시작 덱: 기본 주사위 3종 구성.
func _grant_starting_dice() -> void:
	dice_pool = StarterDeck.build()

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	if current_hp == 0:
		run_ended.emit(false)

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func advance_floor() -> void:
	current_floor += 1
	floor_changed.emit(current_floor)

## 새 스테이지 진입 시 리롤 토큰 지급 (이월 없이 덮어쓰기).
func grant_reroll_tokens(amount: int) -> void:
	reroll_tokens = amount
	reroll_tokens_changed.emit(reroll_tokens)

func spend_reroll_token() -> bool:
	if reroll_tokens <= 0:
		return false
	reroll_tokens -= 1
	reroll_tokens_changed.emit(reroll_tokens)
	return true
