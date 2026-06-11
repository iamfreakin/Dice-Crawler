extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/PreheatReplaySmokeTest.gd
##
## 예열(PREHEAT) = 굴림 시점에 다음 굴림에 걸 보정 pending 생성(AFTER_ROLL),
## 다음 굴림이 소비(BEFORE_ROLL). 증폭과 달리 "앞"을 본다.
## 스킬 주사위 면 순서: [화염(0) 얼음(1) 번개(2) 저주(3) 예열(4) 증폭(5)]
##   토큰→면 = floor(token*6): 0.05=화염, 0.7=예열, 0.9=증폭
## 공격 주사위: value = floor(token*6)+1 → 0.4=값3, 0.05=값1

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData
	_check(attack != null and skill != null, "기본 주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	# 예열 → 공격: 다음 굴림 공격(값3)이 +2 보정을 소비해 5가 된다.
	var battle := BattleManager.new()
	battle._context.add(RollEntry.new(0, skill, 0.7))   # 예열
	battle._context.add(RollEntry.new(1, attack, 0.4))  # 값3 → 소비 후 5
	var rolls := battle.preview_rolls()
	_check(rolls.size() == 2, "replay 결과 수")
	_check(rolls[0].value == 0, "예열 면 자체 값 0")
	_check(rolls[1].value == 5, "다음 굴림 +2 소비")
	_check(rolls[1].face.value == 3, "FaceData 원본 값 불변")
	_check(battle._compute_outcome(null).damage == 5, "예열 보정값 ON_CONFIRM 합산")
	# replay는 매번 새 파생 객체를 만든다.
	var replay_again := battle.preview_rolls()
	_check(rolls[1] != replay_again[1] and replay_again[1].value == 5, "replay 파생 객체 재생성")

	# 예열이 마지막 굴림이면 소비할 대상이 없어 불발한다.
	var trailing := BattleManager.new()
	trailing._context.add(RollEntry.new(0, attack, 0.4))  # 값3
	trailing._context.add(RollEntry.new(1, skill, 0.7))   # 예열(소비자 없음)
	_check(trailing._compute_outcome(null).damage == 3, "마지막 예열 불발")

	# 예열 → 공격 → 증폭: 같은 공격 결과에 예열(+2)과 증폭(+2)이 함께 얹힌다.
	var stacked := BattleManager.new()
	stacked._context.add(RollEntry.new(0, skill, 0.7))   # 예열
	stacked._context.add(RollEntry.new(1, attack, 0.4))  # 값3 +예열2 = 5
	stacked._context.add(RollEntry.new(2, skill, 0.9))   # 증폭 → 직전 +2 = 7
	var stacked_rolls := stacked.preview_rolls()
	_check(stacked_rolls[1].value == 7, "예열+증폭 동시 적용")
	_check(stacked._compute_outcome(null).damage == 7, "예열+증폭 정산")

	# 예열 두 번 연속: 각 예열은 바로 다음 굴림이 소비 → 누적되지 않는다(+4 아님).
	var double := BattleManager.new()
	double._context.add(RollEntry.new(0, skill, 0.7))    # 예열 (pending 2)
	double._context.add(RollEntry.new(1, skill, 0.7))    # 예열: 2 소비 후 새 pending 2 생성
	double._context.add(RollEntry.new(2, attack, 0.4))   # 값3 +2 = 5 (4 아님)
	var double_rolls := double.preview_rolls()
	_check(double_rolls[2].value == 5, "예열 비누적(다음 굴림이 즉시 소비)")
	_check(double._compute_outcome(null).damage == 5, "예열 비누적 정산")

	# 과거 항목의 토큰을 예열이 아닌 면으로 바꾸면 pending이 사라지고 보정도 풀린다.
	var rerolled_entry := battle._context.entries[0]
	rerolled_entry.reissue(0.05)  # 예열 → 화염(피해3 + 화상2)
	var rerolled := battle._compute_outcome(null)
	_check(rerolled.damage == 6, "리롤로 예열 해제 → 화염3+공격3")
	_check(rerolled.burn == 2, "리롤 후 화상 부가효과")

	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Preheat replay smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("Preheat replay smoke test: " + failure)
	quit(1)
