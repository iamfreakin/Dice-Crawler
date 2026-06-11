class_name EffectResolver
extends RefCounted
## ResolvedRoll의 시점별 효과를 처리한다. FaceData와 게임 상태는 직접 수정하지 않는다.


## 방금 굴려진 항목(rolls.back())의 AFTER_ROLL 효과를 처리한다.
## - AMPLIFY_PREVIOUS: 직전 항목의 값을 보정한다 (뒤를 본다, 즉시 적용).
## - PREHEAT_NEXT: 다음 굴림에 걸 보정값을 만든다 (앞을 본다, 생성만).
## 반환: 다음 굴림이 BEFORE_ROLL에서 소비할 보정값. 없으면 0.
static func resolve_after_roll(rolls: Array[ResolvedRoll]) -> int:
	if rolls.is_empty():
		return 0
	var current: ResolvedRoll = rolls.back()
	if current.face == null:
		return 0
	var next_bonus := 0
	for effect in current.face.effects:
		if effect == null or effect.timing != FaceEffectData.Timing.AFTER_ROLL:
			continue
		match effect.effect_type:
			FaceEffectData.EffectType.AMPLIFY_PREVIOUS:
				if rolls.size() < 2:
					continue
				var previous: ResolvedRoll = rolls[rolls.size() - 2]
				previous.modify_value(effect.amount(current.value), current.entry_id)
			FaceEffectData.EffectType.TRANSFORM_PREVIOUS:
				if rolls.size() < 2:
					continue
				var prev: ResolvedRoll = rolls[rolls.size() - 2]
				prev.convert_to(effect.element, current.entry_id)
			FaceEffectData.EffectType.PREHEAT_NEXT:
				next_bonus += effect.amount(current.value)
	return next_bonus


static func resolve_confirm(roll: ResolvedRoll, outcome: BattleOutcome) -> void:
	if roll == null or roll.face == null:
		return
	for effect in roll.face.effects:
		if effect == null or effect.timing != FaceEffectData.Timing.ON_CONFIRM:
			continue
		_apply_confirm(effect, roll, outcome)


static func _apply_confirm(
	effect: FaceEffectData,
	roll: ResolvedRoll,
	outcome: BattleOutcome
) -> void:
	var amount := effect.amount(roll.value)
	match effect.effect_type:
		FaceEffectData.EffectType.DAMAGE:
			outcome.damage += amount
		FaceEffectData.EffectType.BLOCK:
			outcome.block += amount
		FaceEffectData.EffectType.APPLY_BURN:
			outcome.burn += amount
		FaceEffectData.EffectType.GAIN_REROLL:
			outcome.token_gain += amount
	if effect.log_text != "":
		outcome.logs.append(effect.log_text)
