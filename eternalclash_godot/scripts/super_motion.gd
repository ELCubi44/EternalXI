extends RefCounted
## Una biblioteca de movimientos, compartida por todas las apariencias compatibles.
static var shared_library: AnimationLibrary
const PATHS = {
	"hips":"Rig/Hips", "chest":"Rig/Hips/Chest", "head":"Rig/Hips/Chest/Head",
	"arm_l":"Rig/Hips/Chest/ArmL", "arm_r":"Rig/Hips/Chest/ArmR",
	"elbow_l":"Rig/Hips/Chest/ArmL/ElbowL", "elbow_r":"Rig/Hips/Chest/ArmR/ElbowR",
	"leg_l":"Rig/Hips/LegL", "leg_r":"Rig/Hips/LegR",
	"knee_l":"Rig/Hips/LegL/KneeL", "knee_r":"Rig/Hips/LegR/KneeR"
}

static func library() -> AnimationLibrary:
	if shared_library != null:
		return shared_library
	var result = AnimationLibrary.new()
	result.add_animation("shot",_animation(5.2,[
		[0.0,{"arm_l":Vector3(0,0,-15),"arm_r":Vector3(0,0,15)}],
		[1.0,{"chest":Vector3(8,-15,0),"arm_l":Vector3(-25,0,-35),"arm_r":Vector3(25,0,25),"leg_r":Vector3(25,0,0),"knee_r":Vector3(30,0,0)}],
		[2.0,{"chest":Vector3(18,-35,-8),"arm_l":Vector3(-60,0,-45),"arm_r":Vector3(48,0,28),"leg_l":Vector3(-12,0,0),"knee_l":Vector3(15,0,0),"leg_r":Vector3(52,0,0),"knee_r":Vector3(70,0,0)}],
		[2.75,{"chest":Vector3(-10,22,-10),"arm_l":Vector3(30,0,-70),"arm_r":Vector3(-35,0,50),"leg_l":Vector3(8,0,0),"leg_r":Vector3(-100,0,0),"knee_r":Vector3(8,0,0)}],
		[3.3,{"chest":Vector3(14,45,-12),"arm_l":Vector3(45,0,-40),"arm_r":Vector3(-55,0,45),"leg_r":Vector3(-120,0,0),"knee_r":Vector3(25,0,0)}],
		[4.2,{"chest":Vector3(0,15,0),"arm_l":Vector3(0,0,-28),"arm_r":Vector3(0,0,28),"leg_r":Vector3(-12,0,0)}],
		[5.2,{}]
	]))
	result.add_animation("dribble",_animation(4.2,[
		[0.0,{}],
		[.9,{"chest":Vector3(15,0,-15),"leg_l":Vector3(-30,0,0),"knee_l":Vector3(60,0,0),"arm_r":Vector3(-40,0,30),"arm_l":Vector3(30,0,-30)}],
		[1.7,{"hips":Vector3(0,110,0),"chest":Vector3(15,20,12),"leg_r":Vector3(-40,0,30),"knee_r":Vector3(50,0,0),"arm_l":Vector3(-45,0,-55),"arm_r":Vector3(25,0,55)}],
		[2.5,{"hips":Vector3(0,280,0),"chest":Vector3(10,0,-10),"leg_l":Vector3(-45,0,-15),"knee_l":Vector3(50,0,0),"arm_r":Vector3(-40,0,45),"arm_l":Vector3(20,0,-45)}],
		[3.2,{"hips":Vector3(0,360,0),"chest":Vector3(15,0,0),"leg_r":Vector3(-45,0,0),"knee_l":Vector3(35,0,0),"arm_l":Vector3(-40,0,-25)}],
		[4.2,{"hips":Vector3(0,360,0)}]
	]))
	result.add_animation("save",_animation(4.4,[
		[0.0,{"arm_l":Vector3(0,0,-20),"arm_r":Vector3(0,0,20)}],
		[1.1,{"chest":Vector3(12,0,0),"leg_l":Vector3(-25,0,-12),"leg_r":Vector3(-25,0,12),"knee_l":Vector3(40,0,0),"knee_r":Vector3(40,0,0),"arm_l":Vector3(-40,0,-40),"arm_r":Vector3(-40,0,40)}],
		[2.1,{"arm_l":Vector3(-125,0,-20),"arm_r":Vector3(-125,0,20),"elbow_l":Vector3(-25,0,0),"elbow_r":Vector3(-25,0,0),"chest":Vector3(-12,0,0)}],
		[2.8,{"arm_l":Vector3(-95,0,-35),"arm_r":Vector3(-95,0,35),"chest":Vector3(8,0,0),"head":Vector3(10,0,0)}],
		[4.4,{}]
	]))
	shared_library = result
	return result

static func _animation(length: float, poses: Array) -> Animation:
	var anim = Animation.new()
	anim.length = length
	for key in PATHS:
		var track = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track,NodePath(PATHS[key]+":rotation_degrees"))
		anim.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
		for pose in poses:
			anim.track_insert_key(track,pose[0],pose[1].get(key,Vector3.ZERO))
	return anim
