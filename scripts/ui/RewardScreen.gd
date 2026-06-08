extends Control
## 전투 승리 보상 화면. 보상 하나를 선택하면 맵으로 돌아간다.

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "🎁 보상 선택"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_add_reward(vbox, "⚔️ 주사위 강화 (랜덤 숫자 면 +1)", _reward_upgrade)
	_add_reward(vbox, "❤️ 체력 회복 +10", _reward_heal)
	_add_reward(vbox, "✨ 새 스킬 주사위 획득", _reward_new_die)

func _add_reward(parent: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 44)
	btn.pressed.connect(func():
		callback.call()
		SceneRouter.goto(SceneRouter.MAP)
	)
	parent.add_child(btn)

# --- 보상 효과 ----------------------------------------------------------
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
