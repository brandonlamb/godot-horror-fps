extends RigidBody

var view_sensitivity = 0.3;

const walk_speed = 3;
const jump_speed = 3;
const max_accel = 0.02;
const air_accel = 0.05;

var is_moving = false;
var on_floor = false;

var attachment_startpos = Vector3();
var bob_angle = Vector3();
var bob_amount = 0.03;

const FMODE_OFF = 0;
const FMODE_NORMAL = 1;
const FMODE_BRIGHT = 2;

var flash_battery = 100;
var flash_mode = FMODE_OFF;

func _ready():
	flash_mode = FMODE_OFF;
	get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_ENERGY, 0.0);
	get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_SPOT_ANGLE, 25.0);
	
	set_process(true);
	set_process_input(true);


func _input(ie):
	if ie.type == InputEvent.MOUSE_MOTION:
		var yaw = rad2deg(get_node("body").get_rotation().y);
		var pitch = rad2deg(get_node("body/camera").get_rotation().x);
		
		yaw = fmod(yaw - ie.relative_x * view_sensitivity, 360);
		pitch = max(min(pitch - ie.relative_y * view_sensitivity, 90), -90);
		
		get_node("body").set_rotation(Vector3(0, deg2rad(yaw), 0));
		get_node("body/camera").set_rotation(Vector3(deg2rad(pitch), 0, 0));
	
	if ie.type == InputEvent.KEY:
		if ie.pressed && ie.scancode == KEY_F:
			if flash_mode == FMODE_OFF:
				flash_mode = FMODE_NORMAL;
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_ENERGY, 1.0);
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_SPOT_ANGLE, 25.0);
			elif flash_mode == FMODE_NORMAL:
				flash_mode = FMODE_BRIGHT;
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_ENERGY, 2.0);
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_SPOT_ANGLE, 35.0);
			elif flash_mode == FMODE_BRIGHT:
				flash_mode = FMODE_OFF;
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_ENERGY, 0.0);
				get_node("body/camera/attachment/flashlight").set_parameter(Light.PARAM_SPOT_ANGLE, 25.0);

func _integrate_forces(state):
	
	var aim = get_node("body").get_global_transform().basis;
	var direction = Vector3();
	is_moving = false;
	
	if Input.is_key_pressed(KEY_W):
		direction -= aim[2];
		is_moving = true;
	if Input.is_key_pressed(KEY_S):
		direction += aim[2];
		is_moving = true;
	if Input.is_key_pressed(KEY_A):
		direction -= aim[0];
		is_moving = true;
	if Input.is_key_pressed(KEY_D):
		direction += aim[0];
		is_moving = true;
	direction = direction.normalized();
	
	var ray = get_node("ray");
	if ray.is_colliding():
		var up = state.get_total_gravity().normalized();
		var normal = ray.get_collision_normal();
		var floor_velocity = Vector3();
		
		var speed = walk_speed;
		var diff = floor_velocity + direction * walk_speed - state.get_linear_velocity();
		var vertdiff = aim[1] * diff.dot(aim[1]);
		diff -= vertdiff;
		diff = diff.normalized() * clamp(diff.length(), 0, max_accel / state.get_step());
		diff += vertdiff;
		apply_impulse(Vector3(), diff * get_mass());
		
		on_floor = true;
		
		if Input.is_key_pressed(KEY_SPACE):
			#apply_impulse(Vector3(), normal * jump_speed * get_mass());
			apply_impulse(Vector3(), Vector3(0,1,0) * jump_speed * get_mass());
	else:
		apply_impulse(Vector3(), direction * air_accel * get_mass());
		
		on_floor = false;
	state.integrate_forces();

func _enter_tree():
	get_node("body/camera").make_current();
	attachment_startpos = get_node("body/camera/attachment").get_translation();
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _process(delta):
	if is_moving && on_floor:
		var move_speed = 3.0;
		var trans = get_node("body/camera/attachment").get_translation();
		trans = trans.linear_interpolate(Vector3(attachment_startpos.x + bob_amount * -sin(bob_angle.x), attachment_startpos.y + bob_amount * -sin(bob_angle.y), 0), 10*delta);
		get_node("body/camera/attachment").set_translation(trans);
		bob_angle.x += move_speed*1.5*delta;
		if bob_angle.x >= 2*PI:
			bob_angle.x = 0;
		bob_angle.y += move_speed*1.5*delta;
		if bob_angle.y >= PI:
			bob_angle.y = 0;
	else:
		var target = attachment_startpos;
		if !on_floor:
			target.y -= bob_amount;
		
		var trans = get_node("body/camera/attachment").get_translation().linear_interpolate(target, 10*delta);
		get_node("body/camera/attachment").set_translation(trans);
		
		bob_angle.x = 0;
		bob_angle.y = 0;