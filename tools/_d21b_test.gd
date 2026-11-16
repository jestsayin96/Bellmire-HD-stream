extends SceneTree

func _initialize() -> void:
    var tf = Townsfolk.new()
    tf.name = "d21b_target"
    tf.model = "Rogue.glb"
    tf.position = Vector3(0, 0, 0)
    root.add_child(tf)
    await process_frame
    await process_frame
    # Call _flash and _number; they must exist and not error.
    var ok_flash = tf.has_method("_flash")
    var ok_number = tf.has_method("_number")
    var ok_tick = tf.has_method("_tick_flash")
    if not (ok_flash and ok_number and ok_tick):
        print("D21B_FAIL missing methods: flash=%s number=%s tick=%s" % [ok_flash, ok_number, ok_tick])
        quit(1); return
    # Fire number (harmless; adds a Label3D child)
    tf._number(5.0, false)
    tf._number(14.0, true)
    # Fire flash; _mdl may be null in headless (no scene gltf load), guarded.
    tf._flash()
    # Let one frame pass
    await process_frame
    # And HeroBody inherits them
    var has_h_flash = HeroBody.new().has_method("_flash")
    var has_h_number = HeroBody.new().has_method("_number")
    if not (has_h_flash and has_h_number):
        print("D21B_FAIL hero missing methods")
        quit(1); return
    print("D21B_FX OK (townsfolk + hero body have _flash/_number/_tick_flash and run)")
    quit(0)
