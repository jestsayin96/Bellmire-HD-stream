extends SceneTree
## D31a: verify scaffolding is raised when the town levels up and auto-removes
## after SCAFFOLD_LIFE. Boots Town.tscn, forces show_level 2 -> 4 -> 6, checks
## scaffold counts, then forces the lifetime down and verifies cleanup.

func _initialize() -> void:
    _run()

func _run() -> void:
    var ps := load("res://Town.tscn") as PackedScene
    if ps == null:
        print("D31_TEST FAIL: Town.tscn not loadable")
        quit(1)
        return
    var root: Node = ps.instantiate()
    get_root().add_child(root)
    await process_frame
    await process_frame
    await process_frame
    var growth: Node = root.get_node_or_null("Growth")
    if growth == null:
        # Growth might be attached as a child of Town. Scan.
        growth = _find_by_name(root, "Growth")
    if growth == null:
        print("D31_TEST FAIL: Growth node not found under Town")
        quit(1)
        return

    # Baseline: start at 1, go up to measure new scaffolds.
    if growth.has_method("show_level"):
        growth.call("show_level", 1, true)
    await process_frame
    var before := int(growth.call("active_scaffolds"))

    # Jump 1 -> 4 (crosses tiers 2, 3, 4 which unlocks market_hall + stables + more plots)
    growth.call("show_level", 4)
    await process_frame
    var mid := int(growth.call("active_scaffolds"))

    # Jump 4 -> 6 (unlocks guild, bathhouse, mage_tower + more plots)
    growth.call("show_level", 6)
    await process_frame
    var late := int(growth.call("active_scaffolds"))

    # Force SCAFFOLD_LIFE expiry: bend every entry's "until" into the past.
    for s in growth.get("_scaffolds"):
        (s as Dictionary)["until"] = 0.0
    # One _process pass should sweep them.
    await process_frame
    await process_frame
    var cleaned := int(growth.call("active_scaffolds"))

    var ok := before == 0 and mid > 0 and late > mid and cleaned == 0
    print("D31_TEST before=%d mid=%d late=%d cleaned=%d" % [before, mid, late, cleaned])
    if ok:
        print("D31_TEST OK")
        quit(0)
    else:
        print("D31_TEST FAIL (expected before=0 mid>0 late>mid cleaned=0)")
        quit(1)

func _find_by_name(n: Node, nm: String) -> Node:
    if n.name == nm:
        return n
    for c in n.get_children():
        var r := _find_by_name(c, nm)
        if r != null:
            return r
    return null
