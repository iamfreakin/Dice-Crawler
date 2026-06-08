extends Control
## 초기 실행 검증용 데모 화면. 현재 메인 루프는 MainMenu에서 시작한다.

var _hp_label: Label
var _result_label: RichTextLabel
var _token_label: Label


func _ready() -> void:
	GameManager.start_new_run()
	GameManager.grant_reroll_tokens(2)
	_build_ui()
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.reroll_tokens_changed.connect(_on_tokens_changed)
	_refresh_status()


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Dice Crawler 데모"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	_hp_label = Label.new()
	vbox.add_child(_hp_label)

	_token_label = Label.new()
	vbox.add_child(_token_label)

	var roll_btn := Button.new()
	roll_btn.text = "주사위 2개 굴리기"
	roll_btn.pressed.connect(_on_roll_pressed)
	vbox.add_child(roll_btn)

	var dmg_btn := Button.new()
	dmg_btn.text = "피해 5 받기"
	dmg_btn.pressed.connect(func(): GameManager.take_damage(5))
	vbox.add_child(dmg_btn)

	_result_label = RichTextLabel.new()
	_result_label.bbcode_enabled = true
	_result_label.fit_content = true
	_result_label.custom_minimum_size = Vector2(360, 120)
	vbox.add_child(_result_label)


func _on_roll_pressed() -> void:
	var pool := GameManager.dice_pool
	if pool.size() < 2:
		_result_label.text = "주사위 풀이 부족합니다."
		return

	var picks := pool.duplicate()
	picks.shuffle()
	var lines: Array[String] = []
	for i in 2:
		var die: DiceData = picks[i]
		var face: FaceData = die.roll()
		lines.append("%s -> [b]%s[/b]" % [die.display_name, face.label])
	_result_label.text = "\n".join(lines)


func _on_hp_changed(_current: int, _max: int) -> void:
	_refresh_status()


func _on_tokens_changed(_amount: int) -> void:
	_refresh_status()


func _refresh_status() -> void:
	_hp_label.text = "HP: %d / %d   |   층: %d" % [
		GameManager.current_hp, GameManager.max_hp, GameManager.current_floor
	]
	_token_label.text = "리롤 토큰: %d" % GameManager.reroll_tokens
