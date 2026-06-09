extends Control
## 런 맵 화면. 좌표 기반 MapCanvas 를 구동하고, 노드 선택을 라우팅한다.

const REST_HEAL: int = 12

var _status_label: Label
var _scroll: ScrollContainer
var _canvas: MapCanvas


func _ready() -> void:
	theme = UITheme.shared()
	_status_label = $Root/StatusLabel as Label
	_scroll = $Root/Scroll as ScrollContainer
	_render()


func _render() -> void:
	_update_status()

	# 캔버스 새로 구성
	for child in _scroll.get_children():
		child.queue_free()
	_canvas = MapCanvas.new()
	_canvas.node_selected.connect(_on_node_selected)
	_scroll.add_child(_canvas)

	var available := GameManager.get_available_nodes()
	var available_ids: Array[int] = []
	for n in available:
		available_ids.append(n.id)
	var current_id: int = GameManager.current_node.id if GameManager.current_node != null else -1
	_canvas.setup(GameManager.map, available_ids, current_id)
	# 시작 시 아래(현재 위치)쪽이 보이도록 스크롤
	_scroll.set_deferred("scroll_vertical", 100000)


func _update_status() -> void:
	var relic_names: Array[String] = []
	for r in GameManager.relics:
		relic_names.append(r.display_name)
	var relic_part := ("   |   유물: " + ", ".join(relic_names)) if not relic_names.is_empty() else ""
	_status_label.text = "HP: %d/%d   |   골드: %d   |   층: %d%s" % [
		GameManager.current_hp, GameManager.max_hp, GameManager.gold,
		GameManager.current_floor, relic_part
	]


func _on_node_selected(node: MapNode) -> void:
	GameManager.move_to(node)
	match node.type:
		MapNode.Type.BATTLE, MapNode.Type.ELITE, MapNode.Type.BOSS:
			SceneRouter.goto(SceneRouter.BATTLE)
		MapNode.Type.REST:
			GameManager.heal(REST_HEAL)
			_render()
		MapNode.Type.SHOP:
			SceneRouter.goto(SceneRouter.SHOP)
