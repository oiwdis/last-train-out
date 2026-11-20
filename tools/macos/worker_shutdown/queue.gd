extends SceneTree
## Only engine-owned finite tasks survive the test scene. No scripts, nodes,
## GPU handles or audio playbacks are accessed by a worker during shutdown.
func _initialize() -> void:
	var count := 8 if "--pending-work" in OS.get_cmdline_user_args() else 0
	for i in count:
		WorkerThreadPool.add_task(Callable(OS, "delay_msec").bind(200), false, "shutdown regression")
	print("[worker-shutdown] finite tasks submitted: ", count)
	quit()
