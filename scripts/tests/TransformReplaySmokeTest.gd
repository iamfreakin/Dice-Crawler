extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/TransformReplaySmokeTest.gd
##
## 변환(TRANSFORM) = 직전 굴림 결과의 속성 태그를 목표 속성으로 교체(AFTER_ROLL).
## 값/효과는 그대로 두고 시너지 판정 태그만 바꿔 "시너지 완성"에 쓴다. 증폭처럼 직전을 본다.
## 조작 주사위 면 순서: [변환🔥(0) 변환❄️(1) 변환⚡(2) 증폭(3) 예열(4) 숫자2(5)]
##   토큰→면 = floor(token*6): 0.05=변환🔥, 0.9=숫자2
## 스킬 주사위: 0.05=화염(피해3·화상2), 공격 주사위: 0.4=값3

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData
	var manip := load("res://resources/dice/manipulation_die.tres") as DiceData
	_check(attack != null and skill != null and manip != null, "주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	# 숫자(공격3) → 변환🔥: 태그만 FIRE로 바뀌고 값은 3 유지, 원본 FaceData는 NUMBER 그대로.
	var single := BattleManager.new()
	single._context.add(RollEntry.new(0, attack, 0.4))   # 값3 NUMBER
	single._context.add(RollEntry.new(1, manip, 0.05))   # 변환🔥 → 직전을 FIRE로
	var rolls := single.preview_rolls()
	_check(rolls[0].has_tag(DiceData.FaceKind.FIRE), "직전 굴림 FIRE 태그로 변환")
	_check(rolls[0].value == 3, "변환은 값을 바꾸지 않음")
	_check(
		rolls[0].face.has_tag(DiceData.FaceKind.NUMBER)
		and not rolls[0].face.has_tag(DiceData.FaceKind.FIRE),
		"FaceData 원본 태그 불변"
	)
	# 화염 1개뿐이라 시너지 미완성, 피해는 공격3만(변환 면 자체 피해 없음).
	_check(single._compute_outcome(null).damage == 3, "변환 단독은 시너지 미완성")
	# replay는 매번 새 파생 객체.
	var replay_again := single.preview_rolls()
	_check(rolls[0] != replay_again[0] and replay_again[0].has_tag(DiceData.FaceKind.FIRE),
		"replay 파생 객체 재생성")

	# 화염 + 숫자(변환🔥) = 화염 2개 → 시너지 완성(화상 +3).
	var synergy := BattleManager.new()
	synergy._context.add(RollEntry.new(0, skill, 0.05))  # 화염(피해3·화상2)
	synergy._context.add(RollEntry.new(1, attack, 0.4))  # 값3 NUMBER
	synergy._context.add(RollEntry.new(2, manip, 0.05))  # 변환🔥 → 공격을 FIRE로
	var s_out := synergy._compute_outcome(null)
	_check(s_out.damage == 6, "변환으로 화염 시너지 — 피해 3+3")
	_check(s_out.burn == 5, "변환으로 화염 시너지 — 화상 2+3")

	# 변환이 첫 굴림이면 직전이 없어 불발.
	var leading := BattleManager.new()
	leading._context.add(RollEntry.new(0, manip, 0.05))  # 변환🔥 (직전 없음)
	leading._context.add(RollEntry.new(1, attack, 0.4))  # 값3 — 영향 없음
	var l_rolls := leading.preview_rolls()
	_check(not l_rolls[1].has_tag(DiceData.FaceKind.FIRE), "첫 변환 불발(다음 굴림 무영향)")
	_check(leading._compute_outcome(null).damage == 3, "첫 변환 정산 영향 없음")

	# 속성 재지정: 얼음을 화염으로 바꿔 얼음 시너지를 깨고 화염 시너지를 만든다.
	var repurpose := BattleManager.new()
	repurpose._context.add(RollEntry.new(0, skill, 0.05))  # 화염
	repurpose._context.add(RollEntry.new(1, skill, 0.2))   # 얼음(피해3)
	repurpose._context.add(RollEntry.new(2, manip, 0.05))  # 변환🔥 → 얼음을 FIRE로
	var r_out := repurpose._compute_outcome(null)
	_check(r_out.damage == 6, "재지정 후 피해 3+3")
	_check(r_out.burn == 5, "화염 시너지로 전환")
	_check(r_out.apply_weak == 0, "얼음 시너지는 깨짐")

	# 과거 리롤로 변환 면을 숫자로 바꾸면 변환이 풀리고 시너지도 사라진다.
	var rerolled_entry := synergy._context.entries[2]
	rerolled_entry.reissue(0.9)  # 변환🔥 → 숫자2(피해2)
	var rr_out := synergy._compute_outcome(null)
	_check(rr_out.damage == 8, "리롤로 변환 해제 → 화염3+공격3+숫자2")
	_check(rr_out.burn == 2, "변환 해제로 시너지 사라짐(화상 2만)")

	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Transform replay smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("Transform replay smoke test: " + failure)
	quit(1)
