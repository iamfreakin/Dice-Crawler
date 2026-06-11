extends SceneTree
## 실행: Godot --headless --path . --script res://scripts/tests/EffectResolverSmokeTest.gd

var _failures: Array[String] = []


func _init() -> void:
	var attack := load("res://resources/dice/basic_attack.tres") as DiceData
	var defense := load("res://resources/dice/basic_defense.tres") as DiceData
	var skill := load("res://resources/dice/basic_skill.tres") as DiceData

	_check(attack != null and defense != null and skill != null, "기본 주사위 리소스 로드")
	if not _failures.is_empty():
		_finish()
		return

	for face in attack.faces:
		var outcome := _resolve(attack, face)
		_check(outcome.damage == face.value and outcome.block == 0, "공격 숫자 면 %d" % face.value)
		_check(face.has_tag(DiceData.FaceKind.NUMBER), "공격 숫자 태그 %d" % face.value)

	for face in defense.faces:
		var outcome := _resolve(defense, face)
		_check(outcome.block == face.value and outcome.damage == 0, "방어 숫자 면 %d" % face.value)

	var fire := _resolve(skill, skill.faces[0])
	_check(fire.damage == 3 and fire.burn == 2, "화염 면 피해/화상")
	var ice := _resolve(skill, skill.faces[1])
	_check(ice.damage == 3 and skill.faces[1].has_tag(DiceData.FaceKind.ICE), "얼음 면 피해/태그")
	var lightning := _resolve(skill, skill.faces[2])
	_check(
		lightning.damage == 3 and skill.faces[2].has_tag(DiceData.FaceKind.LIGHTNING),
		"번개 면 피해/태그"
	)
	var curse := _resolve(skill, skill.faces[3])
	_check(curse.token_gain == 1 and curse.logs.size() == 1, "저주 면 토큰/로그")
	var preheat := _resolve(skill, skill.faces[4])
	_check(preheat.damage == 0 and preheat.block == 0, "예열 면 단독 확정 효과 없음")
	var amplify := _resolve(skill, skill.faces[5])
	_check(amplify.damage == 0 and amplify.block == 0, "증폭 면 단독 확정 효과 없음")

	var fire_synergy := _resolve_pair(skill, 0.01)
	_check(fire_synergy.damage == 6 and fire_synergy.burn == 7, "불 태그 시너지")
	var ice_synergy := _resolve_pair(skill, 0.2)
	_check(ice_synergy.damage == 6 and ice_synergy.apply_weak == 2, "얼음 태그 시너지")
	var lightning_synergy := _resolve_pair(skill, 0.4)
	_check(
		lightning_synergy.damage == 6 and lightning_synergy.apply_vulnerable == 2,
		"번개 태그 시너지"
	)

	var upgraded := attack.duplicate(true) as DiceData
	upgraded.faces[0].value += 1
	_check(_resolve(upgraded, upgraded.faces[0]).damage == 2, "숫자 면 +1 강화 연동")

	_finish()


func _resolve(die: DiceData, face: FaceData) -> BattleOutcome:
	var outcome := BattleOutcome.new()
	var resolved := ResolvedRoll.new(0, 0, die, face)
	EffectResolver.resolve_confirm(resolved, outcome)
	return outcome


func _resolve_pair(die: DiceData, token: float) -> BattleOutcome:
	var battle := BattleManager.new()
	battle._context.add(RollEntry.new(0, die, token))
	battle._context.add(RollEntry.new(1, die, token))
	return battle._compute_outcome(null)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("EffectResolver smoke test: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error("EffectResolver smoke test: " + failure)
	quit(1)
