extends RefCounted

# 整個畫面位移時以中心微幅放大，放大量剛好遮住位移露出的邊緣。
static func apply(viewport: Viewport, offset: Vector2) -> void:
	var size := viewport.get_visible_rect().size
	var zoom := 1.0 + 2.0 * maxf(absf(offset.x) / size.x, absf(offset.y) / size.y)
	viewport.canvas_transform = Transform2D(0.0, Vector2.ONE * zoom, 0.0, size / 2 * (1.0 - zoom) + offset)

static func reset(viewport: Viewport) -> void:
	viewport.canvas_transform = Transform2D.IDENTITY
