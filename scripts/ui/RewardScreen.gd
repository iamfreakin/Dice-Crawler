extends Control
## 전투 승리 보상 화면.


func _ready() -> void:
	theme = UITheme.shared()
	var reward_box := $Center/RewardBox as VBoxContainer
	_add_reward(reward_box, "주사위 강화: 숫자 면 +1", _reward_upgrade, _tex("dice/basic_attack"))
	_add_reward(reward_box, "체력 회복 +10", _reward_heal)
	_add_reward(reward_box, "스킬 주사위 획득", _reward_new_die, _tex("dice/basic_skill"))

	var relic := _random_unowned_relic()
	if relic != null:
		_add_reward(reward_box, "유물: %s - %s" % [relic.display_name, relic.description],
			func(): GameManager.add_relic(relic), _tex("relics/%s" % relic.id))


func _tex(frag: String) -> Texture2D:
	return load("res://assets/sprites/%s.png" % frag) as Texture2D


func _add_reward(parent: VBoxContainer, text: String, callback: Callable, icon: Texture2D = null) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(360, 52)
	if icon != null:
		btn.icon = icon
		btn.expand_icon = true
	btn.pressed.connect(func():
		callback.call()
		SceneRouter.goto(SceneRouter.MAP)
	)
	parent.add_child(btn)


func _reward_upgrade() -> void:
	var candidates: Array[FaceData] = []
	for d in GameManager.dice_pool:
		for f in d.faces:
			if f.has_tag(DiceData.FaceKind.NUMBER):
				candidates.append(f)
	if candidates.is_empty():
		return
	var f: FaceData = candidates.pick_random()
	f.value += 1
	f.label = str(f.value)


func _reward_heal() -> void:
	GameManager.heal(10)


func _reward_new_die() -> void:
	GameManager.dice_pool.append(StarterDeck.skill_die())


func _random_unowned_relic() -> RelicData:
	var candidates: Array[RelicData] = []
	for r in RelicFactory.all():
		if not GameManager.has_relic(r.id):
			candidates.append(r)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
