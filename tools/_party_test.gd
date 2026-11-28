extends SceneTree
## S165 gate: System 42b party model in roster.gd (DIRECTIVE sup-nov27-1844). Prints PARTY_TEST OK n of n / FAIL.
var _fails := []
var _n := 0
func _ok(c: bool, what: String) -> void:
    _n += 1
    if not c:
        _fails.append(what)
func _initialize() -> void:
    var r := Roster.new()
    root.add_child(r)
    for i in 12:
        r.fresh("u%d" % i, "Hero%d" % i, "knight")
    _ok(Roster.PARTY_CAP == 10, "cap is ten")
    _ok(r.party_create("nobody").contains("no hero"), "no hero cannot lead")
    _ok(r.party_create("u0").contains("gathers"), "u0 leads")
    _ok(r.party_of("u0") == "u0", "leader in own party")
    _ok(r.party_create("u0").contains("already lead"), "no second party")
    _ok(r.party_join("u1", "u0").contains("not invited"), "join needs invite")
    _ok(r.party_invite("u1", "u2").contains("Only"), "non-leader cannot invite")
    for i in range(1, 10):
        r.party_invite("u0", "u%d" % i)
        r.party_join("u%d" % i, "u0")
    _ok(r.party_members("u0").size() == 10, "ten in party, got %d" % r.party_members("u0").size())
    _ok(r.party_members("u0")[0] == "u0", "leader first")
    _ok(r.party_invite("u0", "u10").contains("full"), "eleventh invite refused")
    _ok(r.party_create("u3").contains("already in"), "member cannot lead another")
    _ok(r.party_line("u5").contains("(10 of 10)"), "list line: " + r.party_line("u5"))
    _ok(r.party_kick("u3", "u4").contains("Only"), "non-leader cannot kick")
    _ok(r.party_kick("u0", "u4").contains("turned out") and r.party_of("u4") == "", "leader kicks u4")
    _ok(r.party_leave("u5").contains("leaves") and r.party_of("u5") == "", "member leaves")
    _ok(r.party_members("u0").size() == 8, "eight left")
    # survives a delve ending: note_delve_done touches nothing party-shaped
    r.note_delve_done("u0")
    _ok(r.party_members("u0").size() == 8, "party survives delve end")
    _ok(r.party_create("u10").contains("gathers"), "second party alongside")
    _ok(r.party_invite("u10", "u1").contains("already in"), "cannot invite a member of another")
    _ok(r.party_leave("u0").contains("breaks up") and r.party_of("u1") == "" and not r.parties.has("u0"), "leader leaving dissolves")
    _ok(r.party_disband("u11").contains("Only"), "non-leader cannot disband")
    _ok(r.party_disband("u10").contains("disbands") and r.parties.is_empty(), "disband clears")
    _ok(r.party_line("u0").contains("not in a party"), "no-party line")
    if _fails.is_empty():
        print("PARTY_TEST OK %d of %d" % [_n, _n])
    else:
        print("PARTY_TEST FAIL %d of %d: %s" % [_n - _fails.size(), _n, str(_fails)])
    quit()
