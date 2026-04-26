extends "res://scripts/scenes/BaseScreen.gd"


func _ready() -> void:
    super()
    add_header("엔딩")
    var result = {}
    if game_state().current_ending.is_empty():
        result = game_state().finish_term()
    else:
        result = {
            "ending": data_manager().get_entry("endings", game_state().current_ending),
            "ending_id": game_state().current_ending,
            "score": 0,
            "earned_sign_points": 0
        }

    var ending = result.get("ending", {})
    add_body_label("%s\n%s" % [str(ending.get("name", "엔딩")), str(ending.get("description", ""))])
    add_separator()
    add_button("다음 루프 시작", _on_next_loop)
    add_button("타이틀", _on_title)


func _on_next_loop() -> void:
    game_state().start_next_loop()
    go_to("res://scenes/MainScene.tscn")


func _on_title() -> void:
    go_to("res://scenes/TitleScene.tscn")
