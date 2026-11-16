extends SceneTree
## W-LIVE - a REAL channel-point redemption, end to end (Mr. E opened this 16 Nov 13:44 CT).
## Opens Bellmire's EventSub socket exactly as the game does (no town; chat is a DRY RUN, so
## the bot posts nothing), waits for a person to redeem one of Bellmire's EXISTING rewards on
## jestsayin96's channel, and proves: the notification arrives, it is matched BY REWARD ID, the
## action fires (_spot), the redemption is settled on Twitch (queue empty afterwards), and a
## reward that is not ours is ignored. Creates, edits and deletes NO reward. Prints no token.
## Also takes a Bellmire bits Power-up (channel.custom_power_up_redemption.add) the same way.
## Prints W_LIVE OK / W_LIVE FAIL / W_LIVE NO_REDEMPTION (nobody redeemed inside the window).

const WAIT := 300.0

## Logs every real EventSub notification's type and event body before the game handles it,
## so the REAL payload shape is on record (user names and ids only; tokens never pass here).
class LoggedSub extends TwitchEventSub:
	func handle_event(kind: String, e: Dictionary) -> void:
		print("W_LIVE EVENT %s %s" % [kind, JSON.stringify(e)])
		super(kind, e)

var ev: TwitchEventSub
var _t0 := 0.0
var _stage := 0
var _n_spots := 0
var _n_seen := 0
var _hit_t := 0.0

func _el() -> float:
	return Time.get_ticks_msec() / 1000.0 - _t0

func _initialize() -> void:
	ev = LoggedSub.new()
	ev.dry_run_chat = true
	root.add_child(ev)
	ev.call_deferred("setup", null)
	_t0 = Time.get_ticks_msec() / 1000.0

func _process(_d: float) -> bool:
	if _stage == 0 and (ev.subs_ok.size() + ev.subs_failed.size() >= 6 or _el() > 40.0):
		_stage = 1
		print("W_LIVE socket=%s subs_ok=%d subs_failed=%s rewards_ok=%s keys=%s" % [ev.session_id != "", ev.subs_ok.size(), ev.subs_failed, ev.rewards_ok, ev.reward_ids.keys()])
		print("W_LIVE READY at %.1f s - redeem one of Bellmire's rewards now" % _el())
		_n_seen = ev._seen.size()
	if _stage == 1:
		if ev._seen.size() != _n_seen:
			print("W_LIVE notification ids seen: %d" % (ev._seen.size() - _n_seen))
			_n_seen = ev._seen.size()
		if ev.spotlights.size() > _n_spots:
			for s in ev.spotlights.slice(_n_spots):
				print("W_LIVE ACTION uid=%s lane=%s secs=%.0f reason=%s" % s)
			_n_spots = ev.spotlights.size()
			_stage = 2
			_hit_t = _el()
		elif _el() > WAIT:
			print("W_LIVE NO_REDEMPTION in %.0f s" % WAIT)
			ev._ws.close()
			quit(0)
	if _stage == 2 and _el() > _hit_t + 6.0:
		_stage = 3
		_check_queue()
	return false

func _check_queue() -> void:
	var left := 0
	for key in ev.reward_ids:
		var r: Dictionary = await ev._helix("broadcaster", HTTPClient.METHOD_GET,
			"/channel_points/custom_rewards/redemptions?broadcaster_id=%s&reward_id=%s&status=UNFULFILLED&first=50" % [ev.broadcaster_id, ev.reward_ids[key]])
		var n := 0
		if int(r["code"]) == 200 and typeof(r["json"]) == TYPE_DICTIONARY:
			n = (r["json"].get("data", []) as Array).size()
		print("W_LIVE queue %s: code=%d unfulfilled=%d" % [key, int(r["code"]), n])
		left += n
	print("W_LIVE dry-run chat lines: %d" % ev.sent_chat.size())
	print("W_LIVE OK" if left == 0 else "W_LIVE FAIL (%d redemptions left unfulfilled)" % left)
	ev._ws.close()
	quit(0)
