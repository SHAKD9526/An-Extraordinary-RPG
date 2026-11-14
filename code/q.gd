extends Button

var agreement_dialog: ConfirmationDialog = null
var has_accepted: bool = false

const TERMS_TEXT: String = """
[b]最终用户许可协议（EULA）[/b]

重要说明：
本协议适用于本项目的源代码、编译后的游戏程序、游戏数据包以及内嵌资源素材。
本项目为开源项目，本EULA是本项目的许可协议。

游戏内部分素材采用 CC BY 4.0 协议授权，该部分素材遵循 CC BY 4.0 协议。
若 CC BY 素材协议条款与本EULA冲突，以 CC BY 4.0 协议为准。

下载、查看、编译、运行、体验本游戏程序与源代码，即代表您已经阅读、理解并同意本协议全部条款。
如果您不同意本协议，请不要下载、获取和使用本项目。

[b]一、使用许可[/b]
除标注为 CC BY 4.0 的素材以外，作者授予您有限许可：仅限个人、非商业、不可转让、非独占、可撤销。
- 查看、学习本项目源代码；
- 本地编译、私下游玩体验本游戏；
- 录制游玩截图、视频，用于非商用分享；
- 基于源码修改、调试，仅限个人学习。

不授予任何商用、商用分发、商用衍生作品的相关授权。

标注为 CC BY 4.0 的素材：您可以按照 CC BY 4.0 协议复制、修改、分发（包含商用），但必须按要求标注原作者署名。本EULA不对这类素材增加额外限制。

[b]二、禁止行为[/b]
本条不适用于 CC BY 授权素材，CC BY素材权利以原协议为准。对于非CC BY的源码、程序和资源：
1. 禁止用于任何商业盈利场景，包括售卖、广告变现、付费模组、付费服务等；
2. 禁止单独提取美术、角色、剧情、音频素材，用到其他外部项目；
3. 禁止未经许可打包、分发完整程序或源码包用于商业；
4. 禁止修改源码或资源后，对外发布魔改版本、衍生版本并商用；
5. 禁止利用本游戏内容制作违法、仇恨、造谣类内容。

✅ 允许：学习源码、自己修改自用、非商用发布游玩视频
❌ 禁止：售卖、做付费版本、提取素材商用

[b]三、知识产权[/b]
CC BY素材的版权归对应原作者，适用CC BY 4.0协议。
其余源代码、美术、角色、剧情文本、音频版权归本项目作者所有。
除上面明确授予的权限外，不授予其他知识产权。

[b]四、用户责任与违规后果[/b]
如果您违反本协议使用非CC BY内容，作者有权收回您的使用许可，要求您删除全部相关文件，并保留追究侵权责任的权利。
CC BY素材相关纠纷，按照CC BY 4.0协议与相关法律处理。

[b]五、免责声明[/b]
作者不对程序缺陷、BUG、崩溃、数据异常承担责任。您自行承担下载、编译、运行本项目带来的全部风险。
本项目仅供学习和娱乐使用。

2026
"""

func _ready():
	has_accepted = check_agreement()
	pressed.connect(_on_start_pressed)
	_build_dialog.call_deferred()

func _build_dialog():
	agreement_dialog = ConfirmationDialog.new()
	agreement_dialog.title = "游戏使用协议"
	agreement_dialog.ok_button_text = "同意"
	agreement_dialog.cancel_button_text = "拒绝"
	agreement_dialog.min_size = Vector2i(520, 340)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(480, 260)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var rt_label = RichTextLabel.new()
	rt_label.bbcode_enabled = true
	rt_label.text = TERMS_TEXT
	rt_label.fit_content = true
	rt_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	rt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	scroll.add_child(rt_label)
	vbox.add_child(scroll)
	agreement_dialog.add_child(vbox)

	agreement_dialog.confirmed.connect(_accept_agreement)
	agreement_dialog.canceled.connect(_cancel_agreement)
	get_tree().root.add_child(agreement_dialog)

func _on_start_pressed():
	if has_accepted:
		get_tree().change_scene_to_file("res://gameUI_2.tscn")
	else:
		if agreement_dialog and agreement_dialog.is_inside_tree():
			agreement_dialog.popup_centered_clamped()

func check_agreement() -> bool:
	return FileAccess.file_exists("user://agreement_accepted.save")

func _accept_agreement():
	var file = FileAccess.open("user://agreement_accepted.save", FileAccess.WRITE)
	if file:
		file.close()
	has_accepted = true
	get_tree().change_scene_to_file("res://gameUI_2.tscn")

func _cancel_agreement():
	agreement_dialog.hide()
