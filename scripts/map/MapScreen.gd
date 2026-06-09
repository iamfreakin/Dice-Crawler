extends Control
## 런 맵 화면. 좌표 기반 MapCanvas 를 구동하고, 노드 선택을 라우팅한다.

const REST_HEAL: int = 12

const RELIC_ICON := 36.0

var _status_label: Label
var _scroll: ScrollContainer
var _canvas: MapCanvas
var _relic_box: HBoxContainer


func _ready() -> void:
	theme = UITheme.shared()
	_status_label = $Root/StatusLabel as Label
	_scroll = $Root/Scroll as ScrollContainer
	# 보유 유물 아이콘 줄을 상태 라벨 아래에 삽입
	_relic_box = HBoxContainer.new()
	_relic_box.add_theme_constant_override("separation", 6)
	var root := $Root as VBoxContainer
	root.add_child(_relic_box)
	root.move_child(_relic_box, _status_label.get_index() + 1)
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
	# 스크롤 위치: 현재 노드를 화면 아래쪽에 두어 갈 수 있는(위쪽) 노드가 보이게.
	# 시작(현재 없음)이면 맨 아래(첫 행)로.
	if current_id == -1:
		_scroll.set_deferred("scroll_vertical", 100000)
	else:
		_scroll_to_node(current_id)


func _scroll_to_node(node_id: int) -> void:
	# 배치(_relayout)가 끝난 뒤 좌표가 유효해지므로 두 프레임 대기.
	await get_tree().process_frame
	await get_tree().process_frame
	var cy := _canvas.node_center(node_id).y
	var target := cy - _scroll.size.y * 0.7
	_scroll.scroll_vertical = int(maxf(0.0, target))


func _update_status() -> void:
	_status_label.text = "HP: %d/%d   |   골드: %d   |   층: %d" % [
		GameManager.current_hp, GameManager.max_hp, GameManager.gold,
		GameManager.current_floor
	]
	# 보유 유물 아이콘
	for c in _relic_box.get_children():
		c.queue_free()
	for r in GameManager.relics:
		var tex := load("res://assets/sprites/relics/%s.png" % r.id) as Texture2D
		if tex == null:
			continue
		var tr := TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(RELIC_ICON, RELIC_ICON)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.tooltip_text = "%s — %s" % [r.display_name, r.description]
		_relic_box.add_child(tr)


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
