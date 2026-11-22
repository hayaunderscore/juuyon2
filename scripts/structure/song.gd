extends Resource
class_name Song

enum ChartCompatibility {
	JIRO1 = 0,
	JIRO2,
	TMG, # Equivalent to JIRO1
	TJAP3,
	OOS,
}

@export var title: String
@export var title_localized: Dictionary[String, String]
@export var subtitle: String
@export var subtitle_localized: Dictionary[String, String]
@export var maker: PackedStringArray

@export var demo_start: float = 0.0
@export var head_scroll: float = 1.0

@export var start_bpm: float = 120.0
@export var offset: float = 0.0
@export var wave_path: String
@export var path: String

@export var compatibility_mode: ChartCompatibility = ChartCompatibility.JIRO1

@export var charts: Array[Chart]

func _to_string() -> String:
	var base: String = \
"=================
TITLE: %s
SUBTITLE: %s
BPM: %f
OFFSET: %f
WAVE: %s
DEMOSTART: %f
HEADSCROLL: %f
=================" % [title, subtitle, start_bpm, offset, wave_path, demo_start, head_scroll]

	for chart in charts:
		base += \
"
COURSE: %s
LEVEL: %d
RAW NOTE DATA:
%s
=================" % [Chart.CourseType.find_key(chart.course_type), chart.level, chart.raw_data]

	return base
