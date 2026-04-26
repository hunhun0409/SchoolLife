extends Node

signal state_changed
signal log_added(message: String)

const DAYS = ["월", "화", "수", "목", "금", "토", "일"]
const MAX_WEEKS = 16

var loop_count = 1
var week = 1
var day_index = 0
var stats = {}
var affection = {}
var event_stage = {}
var clues = []
var perks = []
var regular_events_done = []
var sign_points = 0
var weekend_actions_left = 0
var term_finished = false
var current_ending = ""
var log_messages = []


func _ready() -> void:
    new_game()


func new_game() -> void:
    loop_count = 1
    sign_points = 0
    clues.clear()
    perks.clear()
    log_messages.clear()
    _reset_loop_state()
    _add_log("새 학기가 시작되었습니다.")
    state_changed.emit()


func start_next_loop() -> void:
    loop_count += 1
    _reset_loop_state()
    _add_log("%d번째 루프가 시작되었습니다. 단서와 특전은 유지됩니다." % loop_count)
    state_changed.emit()


func get_day_name() -> String:
    return DAYS[day_index]


func get_phase_label() -> String:
    if term_finished:
        return "학기 종료"
    if is_regular_event_due():
        return "정기 이벤트"
    if day_index <= 4:
        return "평일 일정"
    return "주말 행동"


func is_regular_event_due() -> bool:
    if day_index != 0 or term_finished:
        return false
    var event = _data().get_regular_event_for_week(week)
    return not event.is_empty() and not regular_events_done.has(str(event.get("id", "")))


func get_due_regular_event() -> Dictionary:
    if not is_regular_event_due():
        return {}
    return _data().get_regular_event_for_week(week)


func advance_weekday(action_id: String, intensity_id: String) -> Dictionary:
    if day_index > 4 or term_finished:
        return {"message": "평일 행동은 월요일부터 금요일까지만 가능합니다."}

    if _data().get_entry("weekday_actions", action_id).is_empty():
        return {"message": "알 수 없는 평일 행동입니다: %s" % action_id}

    return _advance_weekday_internal(action_id, intensity_id)


func advance_weekdays(schedule: Array) -> Dictionary:
    if day_index != 0 or term_finished:
        return {"message": "월요일 시작 시점에만 월~금 일정을 한 번에 실행할 수 있습니다."}
    if schedule.size() != 5:
        return {"message": "월요일부터 금요일까지 5일치 일정을 모두 정해야 합니다."}

    var start_day_index = day_index
    var messages = []
    var skip_emit = true
    for index in range(schedule.size()):
        var entry = schedule[index]
        if typeof(entry) != TYPE_DICTIONARY:
            day_index = start_day_index
            return {"message": "%s요일 일정이 올바르지 않습니다." % DAYS[index]}

        var action_id = str(entry.get("action_id", ""))
        var intensity_id = str(entry.get("intensity_id", ""))
        if _data().get_entry("weekday_actions", action_id).is_empty():
            day_index = start_day_index
            return {"message": "%s요일 행동을 확인하세요." % DAYS[index]}
        if not _rules().INTENSITIES.has(intensity_id):
            day_index = start_day_index
            return {"message": "%s요일 노력 정도를 확인하세요." % DAYS[index]}

    for entry in schedule:
        var result = _advance_weekday_internal(str(entry["action_id"]), str(entry["intensity_id"]), skip_emit)
        messages.append(str(result.get("message", "")))

    state_changed.emit()
    return {"message": "\n".join(messages)}


func run_weekend_action(location_id: String, action_id: String, character_id: String) -> Dictionary:
    if day_index < 5 or term_finished:
        return {"message": "주말 행동은 토요일과 일요일에만 가능합니다."}
    if weekend_actions_left <= 0:
        return {"message": "남은 주말 행동이 없습니다."}

    var location = _data().get_entry("weekend_locations", location_id)
    var character = _data().get_entry("characters", character_id)
    var action = _find_weekend_action(location, action_id)
    if location.is_empty() or action.is_empty():
        return {"message": "알 수 없는 주말 행동입니다."}

    var result = _rules().calculate_weekend_result(location, action, character, {"affection": affection})
    _add_stat(str(result["stat"]), int(result["stat_gain"]))
    stats["fatigue"] = max(0, int(stats["fatigue"]) + int(result["fatigue_delta"]))

    if not str(result["character_id"]).is_empty():
        _add_affection(str(result["character_id"]), int(result["affection_gain"]))
        _try_unlock_character_event(str(result["character_id"]))

    var clue_id = str(action.get("clue_id", ""))
    if not clue_id.is_empty():
        add_clue(clue_id)

    weekend_actions_left -= 1
    _add_log(str(result["message"]))

    if weekend_actions_left <= 0:
        _advance_after_weekend_day()

    state_changed.emit()
    return result


func run_regular_event(event_id: String) -> Dictionary:
    var event = _data().get_entry("regular_events", event_id)
    if event.is_empty() or regular_events_done.has(event_id):
        return {"message": "처리할 정기 이벤트가 없습니다."}

    var result = _rules().calculate_regular_event_score(event, stats, affection)
    regular_events_done.append(event_id)
    stats["fatigue"] = max(0, int(stats["fatigue"]) + int(event.get("fatigue_gain", 8)))

    var clue_id = str(event.get("clue_id", ""))
    if bool(result["success"]) and not clue_id.is_empty():
        add_clue(clue_id)

    _add_log("%s 결과: %s, 점수 %d" % [str(event.get("name", "정기 이벤트")), str(result["rank"]), int(result["score"])])
    state_changed.emit()
    return result


func finish_term() -> Dictionary:
    term_finished = true
    var ending_id = _evaluate_ending()
    current_ending = ending_id
    var ending = _data().get_entry("endings", ending_id)
    var score = int(stats["intellect"]) + int(stats["stamina"]) + int(stats["charm"]) + clues.size() * 5
    var earned = max(5, int(score / 15))
    sign_points += earned
    _add_log("학기 종료: %s, 징표 포인트 +%d" % [str(ending.get("name", ending_id)), earned])
    state_changed.emit()

    return {
        "ending_id": ending_id,
        "ending": ending,
        "score": score,
        "earned_sign_points": earned
    }


func add_clue(clue_id: String) -> void:
    if clue_id.is_empty() or clues.has(clue_id):
        return
    if not _data().has_entry("clues", clue_id):
        return
    clues.append(clue_id)
    _add_log("단서 획득: %s" % str(_data().get_entry("clues", clue_id).get("name", clue_id)))


func summary_text() -> String:
    return "루프 %d | %d주차 %s요일 | %s\n지력 %d  체력 %d  매력 %d  피로도 %d\n단서 %d | 징표 포인트 %d" % [
        loop_count,
        week,
        get_day_name(),
        get_phase_label(),
        int(stats["intellect"]),
        int(stats["stamina"]),
        int(stats["charm"]),
        int(stats["fatigue"]),
        clues.size(),
        sign_points
    ]


func relationship_text() -> String:
    var lines = []
    for character in _data().get_all("characters"):
        var id = str(character.get("id", ""))
        var value = int(affection.get(id, 0))
        lines.append("%s: 호감도 %d / 단계 %d" % [
            str(character.get("name", id)),
            value,
            _rules().relationship_stage(value)
        ])
    return "\n".join(lines)


func log_text(limit = 10) -> String:
    var start = max(0, log_messages.size() - limit)
    return "\n".join(log_messages.slice(start))


func _reset_loop_state() -> void:
    week = 1
    day_index = 0
    weekend_actions_left = 0
    term_finished = false
    current_ending = ""
    regular_events_done.clear()
    stats = {
        "intellect": 10 + int(_perk_bonus("initial_intellect")),
        "stamina": 10 + int(_perk_bonus("initial_stamina")),
        "charm": 10 + int(_perk_bonus("initial_charm")),
        "fatigue": 0
    }
    affection.clear()
    event_stage.clear()
    for character in _data().get_all("characters"):
        var id = str(character.get("id", ""))
        affection[id] = 0
        event_stage[id] = 0


func _advance_after_weekend_day() -> void:
    if day_index == 5:
        day_index = 6
        weekend_actions_left = _weekend_action_limit()
        _add_log("일요일이 시작되었습니다. 남은 행동: %d" % weekend_actions_left)
        return

    week += 1
    day_index = 0
    weekend_actions_left = 0
    stats["fatigue"] = max(0, int(stats["fatigue"]) - 5)

    if week > MAX_WEEKS:
        finish_term()
    else:
        _add_log("%d주차가 시작되었습니다." % week)


func _find_weekend_action(location: Dictionary, action_id: String) -> Dictionary:
    for action in location.get("actions", []):
        if str(action.get("id", "")) == action_id:
            return action
    return {}


func _add_stat(stat_id: String, amount: int) -> void:
    if not stats.has(stat_id):
        stats[stat_id] = 0
    stats[stat_id] = max(0, int(stats[stat_id]) + amount)


func _add_affection(character_id: String, amount: int) -> void:
    affection[character_id] = clamp(int(affection.get(character_id, 0)) + amount, 0, 100)


func _advance_weekday_internal(action_id: String, intensity_id: String, skip_emit = false) -> Dictionary:
    var action = _data().get_entry("weekday_actions", action_id)
    var growth_bonus = 1.0 + _perk_bonus("weekday_growth")
    var result = _rules().calculate_weekday_result(action, intensity_id, stats, growth_bonus)
    _add_stat(str(result["stat"]), int(result["gain"]))
    stats["fatigue"] = max(0, int(stats["fatigue"]) + int(result["fatigue_gain"]))
    _add_log("%s: %s" % [get_day_name(), str(result["message"])])

    day_index += 1
    if day_index == 5:
        weekend_actions_left = _weekend_action_limit()
        _add_log("주말이 시작되었습니다. 남은 행동: %d" % weekend_actions_left)

    if not skip_emit:
        state_changed.emit()
    return result


func _try_unlock_character_event(character_id: String) -> void:
    var next_stage = _rules().relationship_stage(int(affection.get(character_id, 0)))
    if next_stage <= int(event_stage.get(character_id, 0)):
        return

    event_stage[character_id] = next_stage
    var character = _data().get_entry("characters", character_id)
    _add_log("%s 관계 이벤트 %d단계가 열렸습니다." % [str(character.get("name", character_id)), next_stage])

    var clue_ids = character.get("clue_ids", [])
    var clue_index = next_stage - 1
    if clue_index >= 0 and clue_index < clue_ids.size():
        add_clue(str(clue_ids[clue_index]))


func _evaluate_ending() -> String:
    var max_affection = 0
    var high_relationships = 0
    for value in affection.values():
        max_affection = max(max_affection, int(value))
        if int(value) >= 80:
            high_relationships += 1

    var has_escape_clues = clues.size() >= 8
    var strong_stats = int(stats["intellect"]) >= 80 and int(stats["stamina"]) >= 80 and int(stats["charm"]) >= 80

    if has_escape_clues and high_relationships >= 3 and strong_stats and loop_count >= 2:
        return "true"
    if has_escape_clues and high_relationships >= 1:
        return "escape"
    if high_relationships >= 3:
        return "harem"
    if max_affection >= 80:
        return "heroine"
    return "normal"


func _weekend_action_limit() -> int:
    return 3 if perks.has("extra_weekend_action") else 2


func _perk_bonus(effect_id: String) -> float:
    var total = 0.0
    for perk_id in perks:
        var perk = _data().get_entry("perks", perk_id)
        if str(perk.get("effect", "")) == effect_id:
            total += float(perk.get("value", 0.0))
    return total


func _add_log(message: String) -> void:
    log_messages.append(message)
    if log_messages.size() > 80:
        log_messages.pop_front()
    log_added.emit(message)


func _data() -> Node:
    return get_node("/root/DataManager")


func _rules() -> Node:
    return get_node("/root/GameRules")
