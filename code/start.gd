extends Button

var quit_dialog: ConfirmationDialog

func _ready():
	quit_dialog = $ConfirmationDialog
	if quit_dialog == null:
		push_error("找不到 ConfirmationDialog！检查节点名字和路径")
		return
	pressed.connect(_on_quit_btn_pressed)
	quit_dialog.confirmed.connect(_on_confirm_quit)
	quit_dialog.canceled.connect(_on_cancel_quit)

func _on_quit_btn_pressed():
	quit_dialog.popup_centered()

func _on_confirm_quit():
	get_tree().quit()

func _on_cancel_quit():
	quit_dialog.hide()
