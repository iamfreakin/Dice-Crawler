extends Control
## 전투 승리 보상 화면.


func _ready() -> void:
	theme = UITheme.shared()
	UITheme.add_background(self, "res://assets/sprites/ui/bg_battle.png")

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "보상 선택"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_add_reward(vbox, "주사위 강화: 숫자 면 +1", _reward_upgrade)
	_add_reward(vbox, "체력 회복 +10", _reward_heal)
	_add_reward(vbox, "스킬 주사위 획득", _reward_new_die)

	var relic := _random_unowned_relic()
	if relic != null:
		_add_reward(vbox, "유물: %s - %s" % [relic.display_name, relic.description],
			func(): GameManager.add_relic(relic))


func _add_reward(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 44)
	btn.pressed.connect(func():
		callback.call()
		SceneRouter.goto(SceneRouter.MAP)
	)
	parent.add_child(btn)


func _reward_upgrade() -> void:
	var candidates: Array[FaceData] = []
	for d in GameManager.dice_pool:
		for f in d.faces:
			if f.kind == DiceData.FaceKind.NUMBER:
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
