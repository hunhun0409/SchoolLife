extends "res://scripts/scenes/BaseScreen.gd"

var selected_location_id = ""
var selected_character_id = ""
var selected_action_id = ""
var result_label: Label


func _ready() -> void:
    super()
    add_header("주말")
    add_body_label("남은 행동: %d" % game_state().weekend_actions_left)
    add_separator()
    add_body_label("장소 선택")
    for location in data_manager().get_all("weekend_locations"):
        add_button(str(location["name"]), Callable(self, "_on_location_selected").bind(str(location["id"])))

    add_separator()
    add_body_label("장소를 선택하면 가능한 행동이 표시됩니다.")
    result_label = add_body_label("")
    add_button("실행", _on_run)
    add_button("메인", _on_main)


func _on_location_selected(location_id: String) -> void:
    selected_location_id = location_id
    selected_action_id = ""
    selected_character_id = _default_character_for_location(location_id)
    _update_result("장소: %s" % str(data_manager().get_entry("weekend_locations", location_id).get("name", location_id)))
    _rebuild_action_buttons()


func _rebuild_action_buttons() -> void:
    add_separator()
    var location = data_manager().get_entry("weekend_locations", selected_location_id)
    add_body_label("%s 행동" % str(location.get("name", selected_location_id)))

    for character_id in location.get("characters", []):
        var character = data_manager().get_entry("characters", str(character_id))
        add_button("만나기: %s" % str(character.get("name", character_id)), Callable(self, "_on_character_selected").bind(str(character_id)))

    for action in location.get("actions", []):
        add_button(str(action.get("name", "행동")), Callable(self, "_on_action_selected").bind(str(action.get("id", ""))))


func _on_character_selected(character_id: String) -> void:
    selected_character_id = character_id
    _update_result("인물: %s" % str(data_manager().get_entry("characters", character_id).get("name", character_id)))


func _on_action_selected(action_id: String) -> void:
    selected_action_id = action_id
    var location = data_manager().get_entry("weekend_locations", selected_location_id)
    var action_name = action_id
    for action in location.get("actions", []):
        if str(action.get("id", "")) == action_id:
            action_name = str(action.get("name", action_id))
            break
    _update_result("행동: %s" % action_name)


func _on_run() -> void:
    if selected_location_id.is_empty() or selected_action_id.is_empty():
        _update_result("먼저 장소와 행동을 선택하세요.")
        return

    var result = game_state().run_weekend_action(selected_location_id, selected_action_id, selected_character_id)
    _update_result(str(result.get("message", "완료")))
    go_to("res://scenes/MainScene.tscn")


func _on_main() -> void:
    go_to("res://scenes/MainScene.tscn")


func _default_character_for_location(location_id: String) -> String:
    var location = data_manager().get_entry("weekend_locations", location_id)
    var characters = location.get("characters", [])
    if characters.is_empty():
        return ""
    return str(characters[0])


func _update_result(text: String) -> void:
    if result_label != null:
        result_label.text = text
