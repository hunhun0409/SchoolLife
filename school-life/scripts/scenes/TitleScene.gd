extends "res://scripts/scenes/BaseScreen.gd"

var menu_root: PanelContainer
var menu_content: VBoxContainer


func _ready() -> void:
    _build_title_menu()


func _build_title_menu() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)

    menu_root = PanelContainer.new()
    menu_root.name = "TitleMenuTransform"
    menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    menu_root.anchor_left = 0.3
    menu_root.anchor_top = 0.25
    menu_root.anchor_right = 0.7
    menu_root.anchor_bottom = 0.75
    menu_root.offset_left = 0
    menu_root.offset_top = 0
    menu_root.offset_right = 0
    menu_root.offset_bottom = 0
    add_child(menu_root)

    menu_content = VBoxContainer.new()
    menu_content.name = "TitleMenuButtons"
    menu_content.alignment = BoxContainer.ALIGNMENT_BEGIN
    menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    menu_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    menu_content.add_theme_constant_override("separation", 14)
    menu_root.add_child(menu_content)

    var title_label = Label.new()
    title_label.text = "학교생활"
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.add_theme_font_size_override("font_size", 42)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    menu_content.add_child(title_label)

    _add_title_button("새 게임", _on_new_game)
    _add_title_button("이어하기", _on_continue)
    _add_title_button("불러오기", _on_load_game)
    _add_title_button("갤러리", _on_gallery)
    _add_title_button("종료", _on_quit)


func _add_title_button(text: String, callable: Callable) -> Button:
    var button = Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 48)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(callable)
    menu_content.add_child(button)
    return button


func _on_new_game() -> void:
    game_state().new_game()
    go_to("res://scenes/MainScene.tscn")


func _on_continue() -> void:
    go_to("res://scenes/MainScene.tscn")


func _on_load_game() -> void:
    go_to("res://scenes/MainScene.tscn")


func _on_gallery() -> void:
    go_to("res://scenes/GalleryScene.tscn")


func _on_quit() -> void:
    get_tree().quit()
