class_name GraphicsPreset
extends Resource

@export var display_name := "Medium"
@export_multiline var description := ""
@export_range(0.4, 1.0) var render_scale := 0.85
@export var maximum_3d_height := 1080
@export var volumetric_fog := false
@export var glow := true
@export var directional_shadows := true
@export var local_shadows := false
@export var shadow_atlas_size := 1024
@export var shadow_distance := 45.0
@export var msaa := 0
@export var particle_fraction := 1.0
@export var light_fade_distance := 40.0
@export var light_distance_fade := true
@export var normal_maps := true
@export var roughness_maps := true
@export var skin_scattering := false
@export var ssao := false
@export_range(0.5, 8.0) var mesh_lod_threshold := 2.0
