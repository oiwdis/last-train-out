class_name RenderResolution
extends RefCounted

## The game's root window uses Canvas Items / Expand, so its render target is
## the window's pixel size even when UI coordinates or Retina scaling differ.
static func apply(window: Window, scale: float) -> void:
	# Viewport stores a C++ float. Compute the compensating bias from those
	# exact bytes, including arbitrary height-capped Retina resolutions.
	var stored_scale := Vector2(scale, 0.0).x
	if window.scaling_3d_scale == stored_scale:
		return
	if RenderingServer.get_current_rendering_driver_name() != "metal":
		window.scaling_3d_scale = stored_scale
		return
	# On Godot 4.5.1 both setters *immediately* recreate RD samplers. Release
	# the target as Window does when hidden, set both before any draw, then
	# restore its real size. The next draw creates one final set of buffers.
	# Metal already uses unbiased mipmaps. Keep its actual scale/filtering.
	var rid := window.get_viewport_rid()
	RenderingServer.viewport_set_size(rid, 0, 0)
	window.texture_mipmap_bias = -log(minf(stored_scale, 1.0)) / log(2.0)
	window.scaling_3d_scale = stored_scale
	if window.visible:
		var pixels := window.size.maxi(2)
		RenderingServer.viewport_set_size(rid, pixels.x, pixels.y)
