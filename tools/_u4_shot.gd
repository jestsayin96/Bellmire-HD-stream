extends SceneTree
## U4 - L59's DONE condition: the DIRECTOR PANE must RECOVER when its subject DIES,
## REROLLS or DESPAWNS, instead of freezing on a stale frame (L34). Windowed
## 1920x1080, the 2x2 grid up, the director running.
##
## Each stage first DRIVES the director onto one of our heroes (L18: a chat command
## in the last 2 min makes that hero the pick), confirms it is holding that body,
## and only then perturbs THAT subject. Recovery = the pane is on a live shot and is
## no longer holding the thing we just destroyed. (A run that perturbs a subject the
## director is not watching proves nothing - that was U4's first, discarded attempt.)
## Also: the Chronicle's 18 px line and the lord card's 14 px sub in the 653 px box.
## renders/cycles/20261113_u4.
var _t: Node3D
var _eye: RtsCamera
var _f := 0
var _uids := ["8001", "8002", "8003"]
var _stage := 0
var _phase := "warm"
var _mark := 0
var _try := 0
var _before := ""
var _victim: Node3D = null
var _victim_id := 0
var _results: Array = []
const STAGES := ["DIES", "REROLLS", "DESPAWNS"]
const OUT := "res://renders/cycles/20261113_u4"

func _initialize() -> void:
    _t = (load("res://Town.tscn") as PackedScene).instantiate()
    root.add_child(_t)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

func _save(tag: String) -> void:
    root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))
    print("SAVED ", tag)

func _crop(tag: String, r: Rect2i) -> void:
    var img := root.get_texture().get_image()
    var box := Rect2i(Vector2i.ZERO, img.get_size()).intersection(r)
    if box.size.x <= 0 or box.size.y <= 0:
        return
    img.get_region(box).save_png(ProjectSettings.globalize_path(OUT + "/%s.png" % tag))
    print("CROP ", tag, " ", box)

func _dir():
    return _eye.director if _eye else null

func _body(u: String) -> Node3D:
    var sp := HudDock.spot(_t)
    return sp.body_of(u) if sp else null

## is the director's current shot this exact (live) body?
func _holding(b: Node3D) -> bool:
    var d = _dir()
    if d == null or b == null or not d._cur.has("node"):
        return false
    var n = d._cur["node"]
    return is_instance_valid(n) and n == b

## still showing the thing we destroyed? compared by instance id, because the
## victim may have been freed - passing a freed node to a typed param throws.
func _still_on_victim() -> bool:
    var d = _dir()
    if d == null or _victim_id == 0 or not d._cur.has("node"):
        return false
    var n = d._cur["node"]
    return is_instance_valid(n) and n.get_instance_id() == _victim_id

func _uid() -> String:
    return String(_uids[_stage])

func _process(_dt: float) -> bool:
    _f += 1
    if _f == 20:
        _eye = RtsCamera.new()
        _t.add_child(_eye)
        _eye.setup(_t)
        for i in range(_uids.size()):
            _t.chat_line(String(_uids[i]), "Delver%d" % (i + 1), "!enlist knight")
        _eye.director._set_on(true)
        _phase = "acquire"
        _mark = _f
        return false
    if _f < 120:
        return false

    match _phase:
        "acquire":
            # nudge the director onto this stage's hero, then confirm it is held
            if (_f - _mark) % 60 == 0:
                _t.chat_line(_uid(), "Delver%d" % (_stage + 1), "!hero")
                _try += 1
            var b := _body(_uid())
            if _holding(b):
                _victim = b
                _victim_id = b.get_instance_id()
                _before = String(_dir()._cur.get("key", "-"))
                print("U4 ", STAGES[_stage], " holding uid ", _uid(), " key ", _before)
                if _stage == 0:
                    _save("0_before")
                _phase = "perturb"
            elif _try > 24:
                _results.append("%s: could not get the director onto our hero - NOT TESTED" % STAGES[_stage])
                print("U4 ", _results[_results.size() - 1])
                _next_stage()
        "perturb":
            var r: Roster = _t.get("roster")
            var u := _uid()
            match STAGES[_stage]:
                "DIES":
                    r.kill(u, "the dark below", 3, 1)
                    if is_instance_valid(_victim):
                        _victim.visible = false
                "REROLLS":
                    var h: Dictionary = r.get_hero(u)
                    if not h.is_empty():
                        h["alive"] = true
                        r.reroll(u, true)
                    if is_instance_valid(_victim):
                        _victim.queue_free()       # the reroll remakes the body
                "DESPAWNS":
                    if is_instance_valid(_victim):
                        _victim.queue_free()
            _phase = "settle"
            _mark = _f
        "settle":
            if _f - _mark >= 200:
                var d = _dir()
                var alive: bool = d._shot_alive(d._cur)
                var still := _still_on_victim()
                var ok: bool = alive and not still
                _results.append("%s: before=%s after=%s alive=%s still-on-victim=%s -> %s" % [
                    STAGES[_stage], _before, String(d._cur.get("key", "-")), alive, still,
                    "RECOVERED" if ok else "FROZEN"])
                print("U4 ", _results[_results.size() - 1])
                _save("%d_after_%s" % [_stage + 1, STAGES[_stage].to_lower()])
                _next_stage()
        "card":
            if _f - _mark >= 30:
                _save("4_lord_card_1080")
                var box := HudDock.centre(_t)
                _crop("4_lord_card_crop", Rect2i(int(box.position.x), int(box.position.y),
                    int(box.size.x), int(box.size.y)))
                print("U4 centre box ", box, " CHRON_PX 18 CARD_PX 20 CARD_SUB_PX 14")
                for line in _results:
                    print("U4 RESULT ", line)
                print("U4_SHOT done")
                return true
    if _f > 6000:
        print("U4_SHOT timed out at ", _phase, " stage ", _stage)
        for line in _results:
            print("U4 RESULT ", line)
        return true
    return false

func _next_stage() -> void:
    _stage += 1
    _try = 0
    _victim = null
    _victim_id = 0
    _mark = _f
    if _stage >= STAGES.size():
        FeedHUD.card_on(_t, "Gnawbone, the Rats' Queen",
            "Slain on floor 7 by Delver1, Delver2 and Delver3.", Color(1, 0.8, 0.4))
        _phase = "card"
    else:
        _phase = "acquire"
