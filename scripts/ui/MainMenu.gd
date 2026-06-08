extends Control
## 메인 메뉴. 새 run을 시작하고 맵으로 진입한다.


func _ready() -> void:
	theme = UITheme.shared()
	UITheme.add_background(self, "res://assets/sprites/ui/bg_menu.png")

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "DICE CRAWLER"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "주사위 로그라이크"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var start_btn := Button.new()
	start_btn.text = "게임 시작"
	start_btn.custom_minimum_size = Vector2(200, 44)
	start_btn.pressed.connect(_on_start)
	vbox.add_child(start_btn)

	var quit_btn := Button.new()
	quit_btn.text = "종료"
	quit_btn.custom_minimum_size = Vector2(200, 36)
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)


func _on_start() -> void:
	GameManager.start_new_run()
	SceneRouter.goto(SceneRouter.MAP)
