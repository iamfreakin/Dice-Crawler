extends Control
## 메인 메뉴. 새 run을 시작하고 맵으로 진입한다.


func _ready() -> void:
	theme = UITheme.shared()
	var start_btn := $Center/MenuBox/StartButton as Button
	start_btn.pressed.connect(_on_start)
	var quit_btn := $Center/MenuBox/QuitButton as Button
	quit_btn.pressed.connect(func(): get_tree().quit())


func _on_start() -> void:
	GameManager.start_new_run()
	SceneRouter.goto(SceneRouter.MAP)
