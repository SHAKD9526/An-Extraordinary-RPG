extends Node

# 拿到两个机位，在编辑器拖入
@export var cam_player: PhantomCamera2D
@export var cam_npc: PhantomCamera2D

# 切换到NPC镜头，target传当前这个NPC节点
func switch_to_npc(target: Node2D):
	cam_npc.set_follow_target(target)
	cam_npc.priority = 20
	cam_player.priority = 5

# 切回玩家镜头
func switch_back_to_player():
	cam_npc.set_follow_target(null)
	cam_npc.priority = 5
	cam_player.priority = 10
