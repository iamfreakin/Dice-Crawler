extends Control
## 상점 화면. 골드로 주사위, 유물, 회복을 구매한다.

var _items: Array[Dictionary] = []
var _gold_label: Label
var _items_box: VBoxContainer


func _ready() -> void:
	theme = UITheme.shared()
	_gold_label = $Center/ShopBox/GoldLabel as Label
	_items_box = $Center/ShopBox/ItemsBox as VBoxContainer
	_generate_stock()
	for item in _items:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320, 40)
		btn.pressed.connect(_on_buy.bind(item))
		item["btn"] = btn
		_items_box.add_child(btn)

	var leave := $Center/ShopBox/LeaveButton as Button
	leave.pressed.connect(func(): SceneRouter.goto(SceneRouter.MAP))

	_refresh()


func _generate_stock() -> void:
	_add_item("스킬 주사위", 30, func(): GameManager.dice_pool.append(StarterDeck.skill_die()))
	_add_item("공격 주사위", 25, func(): GameManager.dice_pool.append(StarterDeck.attack_die()))
	_add_item("방어 주사위", 25, func(): GameManager.dice_pool.append(StarterDeck.defense_die()))

	var relic := _random_unowned_relic()
	if relic != null:
		_add_item("유물: %s - %s" % [relic.display_name, relic.description], 65,
			func(): GameManager.add_relic(relic))

	_add_item("체력 회복 +20", 20, func(): GameManager.heal(20))


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
	_gold_label.text = "보유 골드: %d" % GameManager.gold
	for item in _items:
		var btn: Button = item["btn"]
		if btn == null:
			continue
		if item["sold"]:
			btn.text = "%s - 구매 완료" % item["label"]
			btn.disabled = true
		else:
			btn.text = "%s   (%d 골드)" % [item["label"], item["cost"]]
			btn.disabled = GameManager.gold < item["cost"]


func _random_unowned_relic() -> RelicData:
	var candidates: Array[RelicData] = []
	for r in RelicFactory.all():
		if not GameManager.has_relic(r.id):
			candidates.append(r)
	if candidates.is_empty():
		return null
	return candidates.pick_random()
