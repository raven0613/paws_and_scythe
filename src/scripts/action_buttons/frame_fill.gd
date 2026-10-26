@tool
extends RefCounted


# 依外框每列的左右邊界建立完整底色遮罩，與外框使用相同的 9-slice。
static func create_texture(frame: Texture2D) -> ImageTexture:
	var source := frame.get_image()
	var mask := Image.create_empty(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in range(source.get_height()):
		var left := source.get_width()
		var right := -1
		for x in range(source.get_width()):
			if source.get_pixel(x, y).a > 0.0:
				left = mini(left, x)
				right = x
		for x in range(left, right + 1):
			mask.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(mask)
