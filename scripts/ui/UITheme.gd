class_name UITheme
extends RefCounted
## 코드로 구성하는 전역 UI 테마. 각 화면 루트에서 `theme = UITheme.shared()` 로 적용한다.
## 에셋이 준비되면 이 위에 텍스처/폰트를 얹어 확장한다.

static var _theme: Theme = null

# 다크 로그라이크 팔레트
const BG := Color("16161a")
const PANEL := Color("1f1f27")
const BTN := Color("2a2a35")
const BTN_HOVER := Color("3a3a4a")
const BTN_PRESSED := Color("4a4a63")
const BTN_DISABLED := Color("1c1c22")
const ACCENT := Color("7f77dd")
const TEXT := Color("e8e8ec")
const TEXT_DIM := Color("8a8a96")

static func shared() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme

## 화면 루트 뒤에 배경 이미지를 깔아준다 (파일 없으면 무시).
static func add_background(parent: Control, path: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	parent.move_child(rect, 0)

static func _btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_border_width_all(1)
	sb.border_color = border
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func _build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	var font := load("res://assets/fonts/main.ttf") as Font
	if font != null:
		t.default_font = font

	# Button
	t.set_stylebox("normal", "Button", _btn_style(BTN, ACCENT.darkened(0.25)))
	t.set_stylebox("hover", "Button", _btn_style(BTN_HOVER, ACCENT))
	t.set_stylebox("pressed", "Button", _btn_style(BTN_PRESSED, ACCENT))
	t.set_stylebox("disabled", "Button", _btn_style(BTN_DISABLED, Color("2a2a30")))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)

	# Label
	t.set_color("font_color", "Label", TEXT)

	# RichTextLabel
	t.set_color("default_color", "RichTextLabel", TEXT)

	# PanelContainer
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.set_corner_radius_all(8)
	panel.set_content_margin_all(12)
	t.set_stylebox("panel", "PanelContainer", panel)

	return t
