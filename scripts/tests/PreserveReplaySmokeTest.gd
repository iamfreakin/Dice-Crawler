extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/PreserveReplaySmokeTest.gd
##
## 보존(PRESERVE) = 직전 굴림 결과를 다음 턴까지 유지(턴 넘김).
##   TURN_END: 보존 면이 가리킨 직전 결과를 _preserved로 확정(_capture_preserved).
##   TURN_START: 다음 턴 preview_rolls가 _preserved를 맨 앞에 복원(이번 턴 굴림과 콤보/시너지).
## 상한 PRESERVE_CAP(=1), 다시 보존하지 않으면 한 턴 뒤 만료. 핸드 슬롯 없음(hand_index=-1).
## 조작 주사위 면 순서: [변환🔥(0) 변환❄️(1) 보존(2) 증폭(3) 예열(4) 복제(5)]
##   토큰→면 = floor(token*6): 0.4=보존, 0.6=증폭
## 스킬: 0.2=얼음(피해3·ICE), 공격: 0.4=값3 / 0.6=값4

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData
	var manip := load("res://resources/dice/manipulation_die.tres") as DiceData
	_check(attack != null and skill != null and manip != null, "주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	# 얼음 → 보존: 턴 종료 시 얼음 결과가 _preserved로 확정된다.
	var bm := BattleManager.new()
	bm._context.add(RollEntry.new(0, skill, 0.2))   # 얼음(피해3·ICE)
	bm._context.add(RollEntry.new(1, manip, 0.4))   # 보존 → 직전(얼음) 지정
	bm._capture_preserved()
	_check(bm._preserved.size() == 1, "보존 1개 확정")
	_check(bm._preserved[0].has_tag(DiceData.FaceKind.ICE), "보존된 결과 ICE 태그")
	_check(bm._preserved[0].value == 3 and bm._preserved[0].preserved, "보존 값·플래그")

	# 다음 턴: _context를 비우고(턴 경계) 얼음 하나만 굴려도 복원된 얼음과 2개 → 시너지.
	bm._context.clear()
	bm._context.add(RollEntry.new(0, skill, 0.2))   # 이번 턴 얼음
	var next_rolls := bm.preview_rolls()
	_check(next_rolls.size() == 2 and next_rolls[0].preserved, "복원된 보존이 맨 앞")
	var out := bm._compute_outcome(null)
	_check(out.damage == 6, "보존 얼음 + 이번 턴 얼음 = 피해 3+3")
	_check(out.apply_weak == 2, "보존으로 얼음 시너지 완성(약화 2)")

	# 상한: 보존 2회 표시해도 PRESERVE_CAP(1)개만 유지.
	var cap := BattleManager.new()
	cap._context.add(RollEntry.new(0, attack, 0.4))  # 값3
	cap._context.add(RollEntry.new(1, manip, 0.4))   # 보존(값3 지정)
	cap._context.add(RollEntry.new(2, attack, 0.6))  # 값4
	cap._context.add(RollEntry.new(3, manip, 0.4))   # 보존(값4 지정)
	cap._capture_preserved()
	_check(cap._preserved.size() == 1, "보존 상한 1개")
	_check(cap._preserved[0].value == 3, "상한 초과 시 먼저 지정된 결과 유지")

	# 만료: 보존했다가 다음 턴에 보존을 안 하면 _preserved가 비워진다.
	var expire := BattleManager.new()
	expire._context.add(RollEntry.new(0, skill, 0.2))
	expire._context.add(RollEntry.new(1, manip, 0.4))
	expire._capture_preserved()
	_check(expire._preserved.size() == 1, "만료 전 보존 존재")
	expire._context.clear()
	expire._context.add(RollEntry.new(0, attack, 0.4))  # 보존 면 없음
	expire._capture_preserved()
	_check(expire._preserved.is_empty(), "재보존 없으면 한 턴 뒤 만료")

	# 복원된 보존 결과도 이번 턴 증폭 대상이 된다(저장본은 스냅샷이라 불변).
	var amp := BattleManager.new()
	amp._context.add(RollEntry.new(0, skill, 0.2))
	amp._context.add(RollEntry.new(1, manip, 0.4))
	amp._capture_preserved()
	amp._context.clear()
	amp._context.add(RollEntry.new(0, manip, 0.6))      # 증폭 → 복원된 얼음 +2
	_check(amp._compute_outcome(null).damage == 5, "복원된 보존을 증폭(3→5)")
	_check(amp._preserved[0].value == 3, "저장된 스냅샷은 불변")

	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Preserve replay smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("Preserve replay smoke test: " + failure)
	quit(1)
