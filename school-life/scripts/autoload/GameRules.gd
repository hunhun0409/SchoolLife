extends Node

const INTENSITIES = {
    "focus": {
        "label": "열심히",
        "multiplier": 1.5,
        "fatigue": 5
    },
    "normal": {
        "label": "평범하게",
        "multiplier": 1.0,
        "fatigue": 3
    },
    "light": {
        "label": "대충",
        "multiplier": 0.5,
        "fatigue": 1
    }
}

const RELATIONSHIP_THRESHOLDS = [20, 40, 60, 80]


func calculate_weekday_result(action: Dictionary, intensity_id: String, stats: Dictionary, growth_bonus: float) -> Dictionary:
    var intensity = INTENSITIES.get(intensity_id, INTENSITIES["normal"])
    var stat_id = str(action.get("stat", "intellect"))
    var base_value = float(action.get("base_value", 1.0))
    var fatigue = int(stats.get("fatigue", 0))
    var fatigue_penalty = max(0.0, float(fatigue - 40) * 0.03)
    var raw_gain = base_value * float(intensity["multiplier"]) * growth_bonus - fatigue_penalty
    var gain = max(1, int(round(raw_gain)))

    return {
        "stat": stat_id,
        "gain": gain,
        "fatigue_gain": int(intensity["fatigue"]),
        "message": "%s: %s +%d, 피로도 +%d" % [
            str(action.get("name", "행동")),
            stat_label(stat_id),
            gain,
            int(intensity["fatigue"])
        ]
    }


func calculate_weekend_result(location: Dictionary, action: Dictionary, character: Dictionary, state: Dictionary) -> Dictionary:
    var stat_id = str(action.get("stat", character.get("stat", "intellect")))
    var stat_gain = int(action.get("stat_gain", 1))
    var affection_gain = int(action.get("affection_gain", 4))
    var fatigue_delta = int(action.get("fatigue_delta", 2))
    var character_id = str(character.get("id", ""))

    if not character_id.is_empty():
        var current_affection = int(state.get("affection", {}).get(character_id, 0))
        if current_affection >= 40:
            stat_gain += 1
        if current_affection >= 80:
            affection_gain += 1

    return {
        "stat": stat_id,
        "stat_gain": stat_gain,
        "character_id": character_id,
        "affection_gain": affection_gain,
        "fatigue_delta": fatigue_delta,
        "message": "%s / %s: %s +%d, 호감도 +%d" % [
            str(location.get("name", "장소")),
            str(action.get("name", "행동")),
            stat_label(stat_id),
            stat_gain,
            affection_gain
        ]
    }


func calculate_regular_event_score(event: Dictionary, stats: Dictionary, affection: Dictionary) -> Dictionary:
    var weights = event.get("weights", {})
    var score = 0.0
    for stat_id in weights:
        score += float(stats.get(stat_id, 0)) * float(weights[stat_id])

    var linked_character = str(event.get("linked_character", ""))
    if not linked_character.is_empty():
        score += float(affection.get(linked_character, 0)) * 0.25

    var rank = "보통"
    if score >= 110.0:
        rank = "최상"
    elif score >= 80.0:
        rank = "높음"

    return {
        "score": int(round(score)),
        "rank": rank,
        "success": score >= float(event.get("success_score", 70))
    }


func relationship_stage(affection_value: int) -> int:
    var stage = 0
    for threshold in RELATIONSHIP_THRESHOLDS:
        if affection_value >= threshold:
            stage += 1
    return stage


func stat_label(stat_id: String) -> String:
    match stat_id:
        "intellect":
            return "지력"
        "stamina":
            return "체력"
        "charm":
            return "매력"
        "fatigue":
            return "피로도"
        _:
            return stat_id
