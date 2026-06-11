extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/AmplifyReplaySmokeTest.gd

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var defense := load("res://resources/dice/basic_defense.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData
	_check(attack != null and defense != null and skill != null, "기본 주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	# 공격 3 → 증폭: 파생 결과만 5가 되고 원본 FaceData.value는 3으로 유지된다.
	var battle := BattleManager.new()
	battle._context.add(RollEntry.new(0, attack, 0.4))
	battle._context.add(RollEntry.new(1, skill, 0.99))
	var rolls := battle.preview_rolls()
	var replay_again := battle.preview_rolls()
	_check(rolls.size() == 2, "replay 결과 수")
	_check(rolls[0].value == 5, "직전 공격 결과 +2")
	_check(rolls[0].face.value == 3, "FaceData 원본 값 불변")
	_check(rolls[0] != replay_again[0] and replay_again[0].value == 5, "replay 파생 객체 재생성")
	_check(battle._compute_outcome(null).damage == 5, "증폭값 ON_CONFIRM 합산")

	# 증폭을 첫 굴림으로 사용하면 대상이 없어 불발한다.
	var first_amplify := BattleManager.new()
	first_amplify._context.add(RollEntry.new(0, skill, 0.99))
	first_amplify._context.add(RollEntry.new(1, attack, 0.4))
	var first_rolls := first_amplify.preview_rolls()
	_check(first_rolls[0].value == 0 and first_rolls[1].value == 3, "첫 증폭 불발")
	_check(first_amplify._compute_outcome(null).damage == 3, "첫 증폭 정산 영향 없음")

	# 속성 피해만 증가하고 화상 부가 효과는 그대로다.
	var fire_amplify := BattleManager.new()
	fire_amplify._context.add(RollEntry.new(0, skill, 0.01))
	fire_amplify._context.add(RollEntry.new(1, skill, 0.99))
	var fire_outcome := fire_amplify._compute_outcome(null)
	_check(fire_outcome.damage == 5, "화염 피해 +2")
	_check(fire_outcome.burn == 2, "화상 부가 효과 증폭 제외")

	# 과거 항목의 토큰만 교체하면 이후 증폭은 처음부터 replay되어 새 결과를 따른다.
	var rerolled_entry := battle._context.entries[0]
	rerolled_entry.reissue(0.99)
	var rerolled_rolls := battle.preview_rolls()
	_check(rerolled_rolls[0].value == 8, "과거 리롤 후 증폭 재계산")
	_check(battle._compute_outcome(null).damage == 8, "리롤 replay 정산")

	# 방어 결과도 동일하게 값만 증가한다.
	var defense_amplify := BattleManager.new()
	defense_amplify._context.add(RollEntry.new(0, defense, 0.4))
	defense_amplify._context.add(RollEntry.new(1, skill, 0.99))
	_check(defense_amplify._compute_outcome(null).block == 5, "방어 결과 +2")

	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Amplify replay smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("Amplify replay smoke test: " + failure)
	quit(1)
