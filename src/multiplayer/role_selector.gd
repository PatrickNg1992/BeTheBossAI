class_name RoleSelector
extends Control

## Role Selector sub-scene: Host a game room / Join a game / Back to the Menu.
## The Join choice opens an inline form (Player Name, IP, port) with a
## "Connecting…" state and an in-place failure message. The in-game role
## (Player A / Player B / Spectator) is NOT chosen here. All display text
## comes from the multiLang holder.

@onready var choice_box: VBoxContainer = $Center/ChoiceBox
@onready var host_button: Button = $Center/ChoiceBox/HostButton
@onready var join_button: Button = $Center/ChoiceBox/JoinButton
@onready var back_button: Button = $Center/ChoiceBox/BackButton
@onready var join_form: VBoxContainer = $Center/JoinForm
@onready var form_title: Label = $Center/JoinForm/FormTitle
@onready var name_label: Label = $Center/JoinForm/FormGrid/NameLabel
@onready var name_edit: LineEdit = $Center/JoinForm/FormGrid/NameEdit
@onready var ip_label: Label = $Center/JoinForm/FormGrid/IpLabel
@onready var ip_edit: LineEdit = $Center/JoinForm/FormGrid/IpEdit
@onready var port_label: Label = $Center/JoinForm/FormGrid/PortLabel
@onready var port_edit: LineEdit = $Center/JoinForm/FormGrid/PortEdit
@onready var status_label: Label = $Center/JoinForm/StatusLabel
@onready var join_form_button: Button = $Center/JoinForm/FormButtons/JoinFormButton
@onready var join_back_button: Button = $Center/JoinForm/FormButtons/JoinBackButton


func _ready() -> void:
	_update_text()
	Loc.language_changed.connect(_update_text)


func _update_text() -> void:
	host_button.text = Loc.t("role_host")
	join_button.text = Loc.t("role_join")
	back_button.text = Loc.t("role_back")
	form_title.text = Loc.t("join_title")
	name_label.text = Loc.t("join_name")
	name_edit.placeholder_text = Loc.t("join_name_placeholder")
	ip_label.text = Loc.t("join_ip")
	port_label.text = Loc.t("join_port")
	join_form_button.text = Loc.t("join_connect")
	join_back_button.text = Loc.t("join_back")
