extends "res://scripts/scenes/BaseScreen.gd"


func _ready() -> void:
    super()
    add_header("단서 기록")
    if game_state().clues.is_empty():
        add_body_label("획득한 단서가 없습니다.")
    else:
        for clue_id in game_state().clues:
            var clue = data_manager().get_entry("clues", clue_id)
            add_body_label("%s\n%s" % [str(clue.get("name", clue_id)), str(clue.get("description", ""))])
            add_separator()

    add_body_label(_deduction_text())
    add_button("메인", _on_main)


func _deduction_text() -> String:
    if game_state().clues.size() >= 8:
        return "자동 추론: 학기가 반복되고 있으며, 히로인들의 이상 현상은 루프와 연결되어 있습니다."
    if game_state().clues.size() >= 4:
        return "자동 추론: 날짜와 사건이 반복되고 있습니다."
    return "자동 추론: 더 많은 단서가 필요합니다."


func _on_main() -> void:
    go_to("res://scenes/MainScene.tscn")
