class_name Localization
extends Node

## Set to "en" or "zh" before starting the game
@export var language: String = "en":
	set(v):
		language = v
		if _loaded:
			_emit_changed()

signal language_changed()

var _loaded := false
var _translations: Dictionary = {}

const EN := {
	hp_format = "HP: {hp}/{max}",
	bar_count = "x{count}",
	deck_btn = "■ Deck:   {count}",
	discard_btn = "□ Discard:   {count}",
	defeated = "DEFEATED",
	discard_pile = "Discard Pile",
	deck_debug = "Deck (Debug)",
	close = "X",
	casting = "CASTING",
	icon = "ICON",
	card_type_environment = "Environment",
	card_type_monster_skill = "Monster Skill",
	card_type_summoner = "Summoner",
	card_type_minion = "Minion",
	card_desc_environment = "Environment card effect.",
	card_desc_monster_skill = "Monster Skill card effect.",
	card_desc_summoner = "Summoner card effect.",
	card_desc_minion = "Minion card effect.",
	menu_play = "Play",
	menu_multiplayer = "Multiplayer",
	role_host = "Host a game room",
	role_join = "Join a game",
	role_back = "Back to the Menu",
	join_title = "Join a game",
	join_name = "Player Name",
	join_name_placeholder = "Required, max 32 characters",
	join_ip = "IP Address",
	join_port = "Port",
	join_connect = "Join",
	join_back = "Back",
	join_connecting = "Connecting…",
	join_failed = "Connection failed. Check the IP and port, then try again.",
	join_name_required = "Please enter a player name.",
	wr_config = "Room Configuration",
	wr_host_name = "Host Name",
	wr_capacity = "Capacity",
	wr_port = "Port",
	wr_confirm = "Confirm",
	wr_seat_a = "Player A",
	wr_seat_b = "Player B",
	wr_seat_empty = "Empty — click to take",
	wr_spectators = "Spectators",
	wr_start = "Start Game",
	wr_close = "Close Room",
	wr_leave = "Leave",
	notif_host_closed = "The host closed the room.",
	notif_host_offline = "The host went offline.",
	notif_connection_lost = "Connection lost.",
	notif_version_mismatch = "Version mismatch.",
	notif_room_full = "The room is full.",
	notif_serve_failed = "Could not open the room on that port.",
	frozen_waiting = "Waiting for the dropped player to rejoin ({seconds}s)",
	notif_rejoin_only = "A battle is in progress — only the dropped player can rejoin.",
	notif_grace_expired = "The game already ended.",
	timing_play = "Play",
	timing_cancel = "Cancel",
	timing_fast_play = "Fast Play",
	timing_pause = "Pause",
	timing_resume = "Resume",
	timing_action = "Action",
	timing_puck_puck_time = "Puck-puck Time!",
}

const ZH := {
	hp_format = "HP: {hp}/{max}",
	bar_count = "x{count}",
	deck_btn = "■ 牌堆:   {count}",
	discard_btn = "□ 弃牌:   {count}",
	defeated = "已战败",
	discard_pile = "弃牌堆",
	deck_debug = "牌堆 (调试)",
	close = "X",
	casting = "施法中",
	icon = "图标",
	card_type_environment = "场地",
	card_type_monster_skill = "魔王技能",
	card_type_summoner = "召唤者",
	card_type_minion = "仆从",
	card_desc_environment = "场地卡牌效果。",
	card_desc_monster_skill = "魔王技能卡牌效果。",
	card_desc_summoner = "召唤者卡牌效果。",
	card_desc_minion = "仆从卡牌效果。",
	menu_play = "开始",
	menu_multiplayer = "多人对战",
	role_host = "开设游戏房间",
	role_join = "加入游戏",
	role_back = "返回主菜单",
	join_title = "加入游戏",
	join_name = "玩家名称",
	join_name_placeholder = "必填，最多 32 个字符",
	join_ip = "IP 地址",
	join_port = "端口",
	join_connect = "加入",
	join_back = "返回",
	join_connecting = "连接中…",
	join_failed = "连接失败。请检查 IP 和端口后重试。",
	join_name_required = "请输入玩家名称。",
	wr_config = "房间配置",
	wr_host_name = "主机名称",
	wr_capacity = "人数上限",
	wr_port = "端口",
	wr_confirm = "确认",
	wr_seat_a = "玩家 A",
	wr_seat_b = "玩家 B",
	wr_seat_empty = "空位 — 点击入座",
	wr_spectators = "观战者",
	wr_start = "开始游戏",
	wr_close = "关闭房间",
	wr_leave = "离开",
	notif_host_closed = "主机已关闭房间。",
	notif_host_offline = "主机已掉线。",
	notif_connection_lost = "连接已断开。",
	notif_version_mismatch = "版本不匹配。",
	notif_room_full = "房间已满。",
	notif_serve_failed = "无法在该端口开启房间。",
	frozen_waiting = "等待掉线玩家重新加入（{seconds} 秒）",
	notif_rejoin_only = "战斗进行中——仅掉线玩家可重新加入。",
	notif_grace_expired = "对局已结束。",
	timing_play = "行动",
	timing_cancel = "取消",
	timing_fast_play = "加速",
	timing_pause = "暂停",
	timing_resume = "继续",
	timing_action = "敌方行动",
	timing_puck_puck_time = "弹珠时间！",
}


func _ready() -> void:
	_loaded = true
	_translations = _get_table()


func _get_table() -> Dictionary:
	match language:
		"zh":
			return ZH
		_:
			return EN


func t(key: String, args: Dictionary = {}) -> String:
	var table := _translations if _loaded else _get_table()
	var text: String = table.get(key, key)
	for arg in args:
		text = text.replace("{%s}" % arg, str(args[arg]))
	return text


func t_card_type(type_val: int) -> String:
	var key := "card_type_environment"
	match type_val:
		0: key = "card_type_environment"
		1: key = "card_type_monster_skill"
		2: key = "card_type_summoner"
		3: key = "card_type_minion"
	return t(key)


func t_card_desc(type_val: int) -> String:
	var key := "card_desc_environment"
	match type_val:
		0: key = "card_desc_environment"
		1: key = "card_desc_monster_skill"
		2: key = "card_desc_summoner"
		3: key = "card_desc_minion"
	return t(key)


func _emit_changed() -> void:
	_translations = _get_table()
	language_changed.emit()
