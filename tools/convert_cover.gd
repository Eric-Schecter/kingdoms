extends SceneTree
func _initialize():
 var img=Image.load_from_file("res://assets/cover/kingdoms-cover.png")
 assert(img.save_webp("res://assets/cover/kingdoms-cover.webp",true,.88)==OK)
 quit()
