extends Resource
class_name NoiseGenLayer

static func Create(
	name: String,
	layerColor: Color,
	seed: float,
	frequency: float,
	fractalOctaves: float,
	fractalLacunarity: float,
	fractalGain: float,
	curveName: String,
	breakPointActive: bool,
	breakPoint: float
) -> NoiseGenLayer:
	var instance = new()
	instance.Name = name
	instance.LayerColor = layerColor
	instance.Seed = seed
	instance.Frequency = frequency
	instance.FractalOctaves = fractalOctaves
	instance.FractalLacunarity = fractalLacunarity
	instance.FractalGain = fractalGain
	instance.CurveName = curveName
	instance.BreakPointActive = breakPointActive
	instance.BreakPoint = breakPoint
	return instance

@export var Name: String
@export var LayerColor: Color
@export var Seed: float
@export var Frequency: float
@export var FractalOctaves: float
@export var FractalLacunarity: float
@export var FractalGain: float
@export var CurveName: String
@export var BreakPointActive: bool
@export var BreakPoint: float

func _init() -> void:
	randomize()
	
func _save_to_disk():
	ResourceSaver.save(self, "res://Map/NoiseGen/Layers/" + Name + ".tres")

func toNoise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = Seed # defined seed
	noise.seed = int(randf() * 100000)
	noise.frequency = Frequency
	noise.fractal_octaves = FractalOctaves
	noise.fractal_lacunarity = FractalLacunarity
	noise.fractal_gain = FractalGain
	return noise
