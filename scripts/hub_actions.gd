class_name HubActions
extends Node
## S169 (sup-nov27-2340, Option A): the ENGINE half of the hub's order desk. The hub WRITES
## requests into public.hub_actions (schema: web/tools/hub_actions_schema.sql); this node
## POLLS them, decides, and writes back status + a short result.
##
## AN ACTION IS A REQUEST, NOT A RESULT. Every accepted row is turned into the SAME chat
## command the viewer could have typed and run through town.chat_line(twitch_id, ...) - the
## one entry point chat itself uses - so a queued row obeys every rule, cost, gate and
## cooldown a chat command obeys and can never bypass one. Nothing is posted to Twitch: the
## town's answer goes into the row's `result`, not into chat.
##
## Status vocabulary (the schema's): queued -> done | refused | expired.
##  - done     = the town took the request and answered; `result` is the town's own words
##               (which may still be a "you cannot afford that" - the rule decided, not us).
##  - refused  = turned away before dispatch: unknown kind, bad args, bad id, no hero, or a
##               kind the engine does not offer from the hub yet (sell).
##  - expired  = still queued after EXPIRE_S (the game was off, or the viewer kept hitting
##               the chat cooldown). Swept server-side by one PATCH per poll.
## A cooldown hit (chat_line answers "") leaves the row QUEUED for the next poll.
##
## THE TABLE MAY NOT EXIST YET. A 404/400 on the poll marks the desk closed, says so ONCE,
## and backs off to CLOSED_RETRY - it never errors on every beat. Same key file as
## SnapshotPublisher (user://supabase.json, service key, never in the repo); no key = off.
## Starts in play only, beside the snapshot, under the same JESTS_NO_TWITCH guard.

const KEY_FILE := "user://supabase.json"
const POLL_EVERY := 5.0
const FIRST := 25.0
const CLOSED_RETRY := 300.0
const TIMEOUT := 15.0
const BATCH := 5
const EXPIRE_S := 600
const RESULT_MAX := 200
const ARG_MAX := 40
const USER_AGENT := "BellmireHD/1.0"
const KINDS := ["wear", "dye", "sell", "buy", "respec", "reroll", "specialize",
    "party_invite", "party_join", "party_leave"]
## hub counter word -> chat verb (and whether the item word rides along)
const COUNTERS := {"forge": ["forge", true], "armoury": ["armoury", false], "armory": ["armoury", false],
    "brew": ["brew", true], "repair": ["repair", false], "oil": ["oil", true]}

var key_file := KEY_FILE
var enabled := false
var closed := false
var url := ""
var town: Node
var _key := ""
var _http: HTTPRequest
var _t := FIRST
var _busy := false
var _out: Array = []            # pending requests: [path, body] (body "GET" = the poll)
var _said_closed := false

func setup(t: Node) -> void:
    town = t
    _load_key()
    if not enabled:
        print("HUB ACTIONS off: no service key in %s" % key_file)
        return
    _http = HTTPRequest.new()
    _http.name = "HubActionsHTTP"
    _http.use_threads = true
    _http.timeout = TIMEOUT
    add_child(_http)
    _http.request_completed.connect(_on_done)
    print("HUB ACTIONS on: polling every %d s" % int(POLL_EVERY))

func _load_key() -> void:
    enabled = false
    if not FileAccess.file_exists(key_file):
        return
    var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(key_file))
    if typeof(j) != TYPE_DICTIONARY:
        return
    url = String(j.get("url", "")).strip_edges().trim_suffix("/")
    _key = String(j.get("service_key", "")).strip_edges()
    enabled = url.begins_with("https://") and _key != ""

func _headers() -> PackedStringArray:
    return PackedStringArray(["apikey: " + _key, "Authorization: Bearer " + _key,
        "Content-Type: application/json", "User-Agent: " + USER_AGENT, "Prefer: return=minimal"])

func _process(delta: float) -> void:
    if not enabled or _busy:
        return
    if not _out.is_empty():
        var job: Array = _out.pop_front()
        _send(String(job[0]), String(job[1]))
        return
    _t -= delta
    if _t > 0.0:
        return
    _t = CLOSED_RETRY if closed else POLL_EVERY
    if not closed:
        _sweep_expired()
    _out.append(["/rest/v1/hub_actions?status=eq.queued&order=created_at.asc&limit=%d&select=id,twitch_id,viewer_login,kind,args" % BATCH, "GET"])

func _sweep_expired() -> void:
    var cut := Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) - EXPIRE_S) + "Z"
    _out.append(["/rest/v1/hub_actions?status=eq.queued&created_at=lt." + cut.uri_encode(),
        JSON.stringify({"status": "expired", "result": "The town did not get to this in time - file it again.",
            "updated_at": _now_iso()})])

func _send(path: String, body: String) -> void:
    var method := HTTPClient.METHOD_PATCH
    if body == "GET":
        method = HTTPClient.METHOD_GET
        body = ""
    _busy = true
    var err := _http.request(url + path, _headers(), method, body)
    if err != OK:
        _busy = false

func _on_done(res: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
    _busy = false
    if res != HTTPRequest.RESULT_SUCCESS:
        return
    if code == 404 or code == 400:
        if not closed:
            closed = true
            _out.clear()
            if not _said_closed:
                _said_closed = true
                print("HUB ACTIONS: the order desk table is not there yet (HTTP %d) - retrying every %d s" % [code, int(CLOSED_RETRY)])
        return
    if code < 200 or code >= 300:
        return
    if closed:
        closed = false
        print("HUB ACTIONS: the order desk is open")
    var j: Variant = JSON.parse_string(body.get_string_from_utf8())
    if typeof(j) != TYPE_ARRAY:
        return                       # a PATCH answer (return=minimal) - nothing to read
    for row in j:
        if typeof(row) != TYPE_DICTIONARY:
            continue
        var v := decide(row)
        if v.is_empty():
            continue                 # cooldown: stays queued for the next poll
        var id := int(row.get("id", 0))
        if id <= 0:
            continue
        _out.append(["/rest/v1/hub_actions?id=eq.%d&status=eq.queued" % id,
            JSON.stringify({"status": v["status"], "result": v["result"], "updated_at": _now_iso()})])

func _now_iso() -> String:
    return Time.get_datetime_string_from_system(true) + "Z"

# ---------------------------------------------------------------- the decision (pure, tested)

static func clean(v: Variant) -> String:
    var s := String(v if v != null else "").to_lower().strip_edges()
    var o := ""
    for ch in s:
        var c := ch.unicode_at(0)
        if (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or ch in [" ", "-", "_", "'"]:
            o += ch
    while o.find("  ") >= 0:
        o = o.replace("  ", " ")
    return o.strip_edges().substr(0, ARG_MAX)

## kind + args -> the chat line the viewer could have typed, or {"refuse": why}.
static func translate(kind: String, args: Dictionary) -> Dictionary:
    match kind:
        "wear":
            var it := clean(args.get("item", ""))
            return {"line": "!wear " + it} if it != "" else {"refuse": "Name the item to wear."}
        "dye":
            var col := clean(args.get("colour", ""))
            return {"line": "!dye " + col} if col != "" else {"refuse": "Name a colour."}
        "sell":
            return {"refuse": "Selling from the inn is not open yet - the counter buys on stream."}
        "buy":
            var ctr := clean(args.get("counter", ""))
            if not COUNTERS.has(ctr):
                return {"refuse": "No such counter. Try forge, armoury, brew, repair or oil."}
            var c: Array = COUNTERS[ctr]
            var it2 := clean(args.get("item", ""))
            return {"line": "!" + String(c[0]) + ((" " + it2) if bool(c[1]) and it2 != "" else "")}
        "respec":
            # chat's !respec takes the new CALLING; the hub's H33 form sends no box yet, so a bare
            # respec is answered by the town's own "No such calling. Try: ..." (S169, flagged to hub)
            var p := clean(args.get("calling", args.get("class", args.get("path", ""))))
            return {"line": "!respec" + ((" " + p) if p != "" else "")}
        "reroll":
            return {"line": "!reroll"}
        "specialize":
            var p2 := clean(args.get("path", ""))
            return {"line": "!specialize " + p2} if p2 != "" else {"refuse": "Name the path."}
        "party_invite", "party_join":
            var w := clean(args.get("who", "")).replace(" ", "")
            if w == "":
                return {"refuse": "Name the viewer."}
            return {"line": "!party %s %s" % [kind.substr(6), w]}
        "party_leave":
            return {"line": "!party leave"}
    return {"refuse": "The town does not know that request."}

## One row -> {status, result}, or {} to leave it queued (the viewer's chat cooldown).
## The engine decides: the request runs through town.chat_line exactly as chat would.
func decide(row: Dictionary) -> Dictionary:
    var uid := String(row.get("twitch_id", "")).strip_edges()
    var kind := String(row.get("kind", ""))
    if uid == "" or not uid.is_valid_int() or uid.length() > 20 or uid.begins_with("-"):
        return _v("refused", "The town could not tell who sent this.")
    if not kind in KINDS:
        return _v("refused", "The town does not know that request.")
    var args: Variant = row.get("args", {})
    var tr := translate(kind, args if typeof(args) == TYPE_DICTIONARY else {})
    if tr.has("refuse"):
        return _v("refused", String(tr["refuse"]))
    var r: Roster = town.get("roster") if town else null
    if r == null or r.get_hero(uid).is_empty():
        return _v("refused", "No hero yet - type !enlist in chat first.")
    var display := clean(row.get("viewer_login", ""))
    if display == "":
        display = String(r.get_hero(uid).get("name", ""))
    var out := String(town.chat_line(uid, display, String(tr["line"])))
    if out.strip_edges() == "":
        return {}
    return _v("done", out)

static func _v(status: String, result: String) -> Dictionary:
    return {"status": status, "result": result.strip_edges().substr(0, RESULT_MAX)}
