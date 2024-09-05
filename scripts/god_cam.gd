extends Camera3D

var move_speed = 20.0
var rotate_speed = 0.05
var zoom_speed = 0.5
var target = null

func is_free():
	return target == null

func _ready():
	# Ensure the camera uses smoothed movement and capture input
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	handle_input(event)

func _process(delta):
	# We actually don't want the cam moving faster when spead up
	delta /= Engine.time_scale
	if is_free(): process_free_movement(delta)
	else: process_targeted_movement(delta)

func handle_input(event):
	if event is InputEventMouseMotion and is_free():
		rotate_y(deg_to_rad(-event.relative.x * rotate_speed))
		rotation.x += deg_to_rad(-event.relative.y * rotate_speed)
		# Limit pitch to avoid gimbal lock
		rotation.x = clamp(rotation.x, deg_to_rad(-80), deg_to_rad(80))
	elif event is InputEventMouseButton and not is_free():
		var zoom_direction = 0
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_direction = -1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_direction = 1
		translate(Vector3(0, 0, zoom_direction * zoom_speed))

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL:
			move_speed += 1
		elif event.keycode == KEY_MINUS:
			move_speed -= 1
			move_speed = max(move_speed, 1)  # Prevent camera speed from going negative
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()

func process_free_movement(delta):
	var velocity = Vector3()
	var speed = move_speed
	if Input.is_key_pressed(KEY_SHIFT): speed *= 2
	if Input.is_key_pressed(KEY_W): velocity.z -= 1
	if Input.is_key_pressed(KEY_S): velocity.z += 1
	if Input.is_key_pressed(KEY_A): velocity.x -= 1
	if Input.is_key_pressed(KEY_D): velocity.x += 1
	if Input.is_key_pressed(KEY_SPACE): velocity.y += 1
	if Input.is_key_pressed(KEY_CTRL): velocity.y -= 1
	velocity = velocity.normalized() * speed
	translate(velocity * delta)

func process_targeted_movement(delta):
	var target_pos = target.global_transform.origin
	var cam_to_target = target_pos - global_transform.origin
	var rot = [Vector3(), deg_to_rad(-1)]
	if Input.is_key_pressed(KEY_W): rot = [Vector3(1, 0, 0), deg_to_rad(1)]
	if Input.is_key_pressed(KEY_S): rot = [Vector3(1, 0, 0), deg_to_rad(-1)]
	if Input.is_key_pressed(KEY_A): rot = [Vector3(0, 1, 0), deg_to_rad(1)]
	if Input.is_key_pressed(KEY_D): rot = [Vector3(0, 1, 0), deg_to_rad(-1)]
	rotate_object_local(rot[0], rot[1])

func set_target(new_target):
	target = new_target

func set_free_mode():
	target = null
