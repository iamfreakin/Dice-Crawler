extends Node
## 런(run) 전역 상태 관리 Autoload 싱글톤.
## project.godot 에 Autoload 이름 "GameManager" 로 등록한다.
## 씬 간 직접 참조 대신 이 매니저와 시그널을 경유해 상태를 공유한다.

signal hp_changed(current: int, max: int)
signal floor_changed(floor: int)
signal reroll_tokens_changed(amount: int)
signal run_started
signal run_ended(victory: bool)

## --- 플레이어 런 상태 ---
var max_hp: int = 50
var current_hp: int = 50
var current_floor: int = 0

## 주사위 풀(덱). 전투 시 여기서 드로우한다.
var dice_pool: Array[DiceData] = []
## 보유 유물.
var relics: Array[Resource] = []

## 스테이지당 리롤 토큰 (미사용 시 소멸, 이월 없음).
var reroll_tokens: int = 0

func start_new_run() -> void:
	current_hp = max_hp
	current_floor = 0
	dice_pool.clear()
	relics.clear()
	reroll_tokens = 0
	_grant_starting_dice()
	run_started.emit()

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
