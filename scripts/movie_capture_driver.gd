extends Node
var frames=0
func _process(delta):
 RenderingServer.force_draw(false,delta)
 frames+=1
func _exit_tree(): print("FORCED DRAW FRAMES: ",frames)
