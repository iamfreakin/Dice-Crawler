class_name EffectResolver
extends RefCounted
## ResolvedRoll의 시점별 효과를 처리한다. FaceData와 게임 상태는 직접 수정하지 않는다.


static func resolve_after_roll(rolls: Array[ResolvedRoll]) -> void:
	if rolls.is_empty():
		return
	var current := rolls.back()
	if current.face == null:
		return
	for effect in current.face.effects:
		if effect == null or effect.timing != FaceEffectData.Timing.AFTER_ROLL:
			continue
		match effect.effect_type:
			FaceEffectData.EffectType.AMPLIFY_PREVIOUS:
				if rolls.size() < 2:
					continue
				var previous := rolls[rolls.size() - 2]
				previous.modify_value(effect.amount(current.value), current.entry_id)


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
