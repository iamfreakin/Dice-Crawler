extends Control
## 상점 화면. 골드로 주사위/유물/회복을 구매한다. 입장 시 재고가 정해진다.

var _items: Array[Dictionary] = []  ## {label, cost, action: Callable, sold: bool, btn: Button}
var _gold_label: Label

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "🛒 상점"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_gold_label)

	vbox.add_child(HSeparator.new())

	_generate_stock()
	for item in _items:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320, 40)
		btn.pressed.connect(_on_buy.bind(item))
		item["btn"] = btn
		vbox.add_child(btn)

	vbox.add_child(HSeparator.new())

	var leave := Button.new()
	leave.text = "🚪 상점 나가기"
	leave.custom_minimum_size = Vector2(320, 40)
	leave.pressed.connect(func(): SceneRouter.goto(SceneRouter.MAP))
	vbox.add_child(leave)

	_refresh()

func _generate_stock() -> void:
	_add_item("✨ 스킬 주사위", 30, func(): GameManager.dice_pool.append(StarterDeck.skill_die()))
	_add_item("⚔️ 공격 주사위", 25, func(): GameManager.dice_pool.append(StarterDeck.attack_die()))
	_add_item("🛡️ 방어 주사위", 25, func(): GameManager.dice_pool.append(StarterDeck.defense_die()))
	var relic := _random_unowned_relic()
	if relic != null:
		_add_item("🏺 %s — %s" % [relic.display_name, relic.description], 65,
			func(): GameManager.add_relic(relic))
	_add_item("❤️ 체력 회복 +20", 20, func(): GameManager.heal(20))

func _add_item(label: String, cost: int, action: Callable) -> void:
	_items.append({"label": label, "cost": cost, "action": action, "sold": false, "btn": null})

func _on_buy(item: Dictionary) -> void:
	if item["sold"]:
		return
	if not GameManager.spend_gold(item["cost"]):
		return
	(item["action"] as Callable).call()
	item["sold"] = true
	_refresh()

func _refresh() -> void:
	_gold_label.text = "보유 골드: 💰 %d" % GameManager.gold
	for item in _items:
		var btn: Button = item["btn"]
		if btn == null:
			continue
		if item["sold"]:
			btn.text = "%s — 구매완료" % item["label"]
			btn.disabled = true
		else:
			btn.text = "%s   (💰 %d)" % [item["label"], item["cost"]]
			btn.disabled = GameManager.gold < item["cost"]

## 아직 보유하지 않은 유물 중 하나를 무작위로 고른다. 없으면 null.
func _random_unowned_relic() -> RelicData:
	var candidates: Array[RelicData] = []
	for r in RelicFactory.all():
		if not GameManager.has_relic(r.id):
			candidates.append(r)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
