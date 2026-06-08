extends Node
## 씬 전환 라우터 Autoload. 씬 경로를 한 곳에서 관리한다.
## project.godot 에 Autoload 이름 "SceneRouter" 로 등록한다.

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const MAP := "res://scenes/Map.tscn"
const BATTLE := "res://scenes/Battle.tscn"
const REWARD := "res://scenes/Reward.tscn"
const SHOP := "res://scenes/Shop.tscn"

func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)
