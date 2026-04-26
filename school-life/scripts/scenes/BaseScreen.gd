extends Control

var content: VBoxContainer


func _ready() -> void:
    _build_base()


func add_header(title: String) -> void:
    var label = Label.new()
    label.text = title
    label.add_theme_font_size_override("font_size", 28)
    content.add_child(label)


func add_body_label(text: String) -> Label:
    var label = Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(label)
    return label


func add_button(text: String, callable: Callable) -> Button:
    var button = Button.new()
    button.text = text
    button.pressed.connect(callable)
    content.add_child(button)
    return button


func add_separator() -> void:
    var separator = HSeparator.new()
    content.add_child(separator)


func go_to(path: String) -> void:
    var root = get_tree().current_scene
    if root != null and root.has_method("show_screen"):
        root.show_screen(path)
    else:
        get_tree().change_scene_to_file(path)


func game_state() -> Node:
    return get_node("/root/GameState")


func data_manager() -> Node:
    return get_node("/root/DataManager")


func game_rules() -> Node:
    return get_node("/root/GameRules")


func _build_base() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    var scroll = ScrollContainer.new()
    scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)

    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    scroll.add_child(content)
