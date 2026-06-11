extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/DuplicateReplaySmokeTest.gd
##
## 복제(DUPLICATE) = 직전 굴림 결과(보정·변환 반영된 상태)를 복사해 파생 굴림 하나 추가(AFTER_ROLL).
## 복사본은 generated=true, 핸드 슬롯은 원본과 공유(별도 주사위 칩 없음). 피해·시너지·화상이 2배가 된다.
## 조작 주사위 면 순서: [변환🔥(0) 변환❄️(1) 변환⚡(2) 증폭(3) 예열(4) 복제(5)]
##   토큰→면 = floor(token*6): 0.6=증폭, 0.7=예열, 0.9=복제
## 스킬: 0.05=화염(피해3·화상2), 공격: 0.4=값3

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData
	var manip := load("res://resources/dice/manipulation_die.tres") as DiceData
	_check(attack != null and skill != null and manip != null, "주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	# 숫자(공격3) 복제 → 파생 굴림 추가, 피해 2배. 원본/FaceData는 불변.
	var single := BattleManager.new()
	single._context.add(RollEntry.new(0, attack, 0.4))   # 값3
	single._context.add(RollEntry.new(1, manip, 0.9))    # 복제
	var rolls := single.preview_rolls()
	_check(rolls.size() == 3, "복제로 파생 굴림 1개 추가")
	_check(rolls[2].generated and rolls[2].value == 3, "복사본은 generated·값 복사")
	_check(rolls[2].source_entry_id == 0, "복사본 출처 = 원본 entry_id")
	_check(rolls[0].value == 3 and rolls[0].face.value == 3, "원본·FaceData 불변")
	_check(single._compute_outcome(null).damage == 6, "복제로 피해 3→6")
	# replay는 매번 새로 만든다(복사본도 매번 재생성).
	_check(single.preview_rolls().size() == 3, "replay마다 복사본 재생성")

	# 화염 복제 → 화염 2개 시너지 + 화상 2배.
	var synergy := BattleManager.new()
	synergy._context.add(RollEntry.new(0, skill, 0.05))  # 화염(피해3·화상2)
	synergy._context.add(RollEntry.new(1, manip, 0.9))   # 복제
	var s_out := synergy._compute_outcome(null)
	_check(s_out.damage == 6, "화염 복제 — 피해 3+3")
	_check(s_out.burn == 7, "화염 복제 — 화상 2+2+시너지3")

	# 복제가 첫 굴림이면 직전이 없어 불발(복사본 없음).
	var leading := BattleManager.new()
	leading._context.add(RollEntry.new(0, manip, 0.9))   # 복제 (직전 없음)
	leading._context.add(RollEntry.new(1, attack, 0.4))  # 값3
	var l_rolls := leading.preview_rolls()
	_check(l_rolls.size() == 2, "첫 복제 불발 — 복사본 없음")
	_check(leading._compute_outcome(null).damage == 3, "첫 복제 정산 영향 없음")

	# 예열 → 공격 → 복제: 복사본은 예열 보정이 반영된 값(5)을 복사한다.
	var boosted := BattleManager.new()
	boosted._context.add(RollEntry.new(0, manip, 0.7))   # 예열(+2 pending)
	boosted._context.add(RollEntry.new(1, attack, 0.4))  # 값3 → 5
	boosted._context.add(RollEntry.new(2, manip, 0.9))   # 복제 → 5 복사
	var b_rolls := boosted.preview_rolls()
	_check(b_rolls.size() == 4 and b_rolls[3].value == 5, "복제는 보정 후 값(5)을 복사")
	_check(boosted._compute_outcome(null).damage == 10, "보정값 복제 — 피해 5+5")

	# 과거 리롤로 복제 면을 증폭으로 바꾸면 복사본이 사라진다.
	var rerolled_entry := single._context.entries[1]
	rerolled_entry.reissue(0.6)  # 복제 → 증폭(직전 +2)
	var rr_rolls := single.preview_rolls()
	_check(rr_rolls.size() == 2, "리롤로 복제 해제 — 복사본 제거")
	_check(single._compute_outcome(null).damage == 5, "증폭으로 바뀌어 공격 3→5")

	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("Duplicate replay smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("Duplicate replay smoke test: " + failure)
	quit(1)
