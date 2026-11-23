extends Node

var header_regex: RegEx = RegEx.new()
var command_regex: RegEx = RegEx.new()
var comment_regex: RegEx = RegEx.new()

func _ready() -> void:
	header_regex.compile("^[ \t]*([^ \t:]*)[ \t]*:(.*)$")
	command_regex.compile("^[ \t]*#([^ \t]*[A-Z_]+)[ \t]?(.*)$")
	comment_regex.compile("(\\/\\/)(.+?)(?=[\\n\\r]|\\*\\))")

func _get_header(line: String) -> PackedStringArray:
	var matches: RegExMatch = header_regex.search(line)
	if not matches: return []
	return [matches.get_string(1).strip_edges().to_lower(), matches.get_string(2).strip_edges()]

func _get_command(line: String) -> PackedStringArray:
	if not line.begins_with("#"): return []
	var matches: RegExMatch = command_regex.search(line)
	if not matches: return []
	return [matches.get_string(1).strip_edges().to_lower(), matches.get_string(2).strip_edges()]

# Only reads metadata, and nothing else!
func parse_tja_metadata(path: String) -> Song:
	var song: Song = Song.new()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	song.path = path
	
	var chart_metadata: bool = false
	var current_chart: Chart = Chart.new()
	while file.get_position() < file.get_length():
		# Current line
		var line: String = file.get_line().strip_edges()
		# Empty?
		if line.is_empty() or line.begins_with("//"): continue
		line = comment_regex.sub(line+"\n", "", true).strip_escapes().strip_edges()

		if line.begins_with("#START"):
			chart_metadata = true
		elif line.begins_with("#END"):
			chart_metadata = false
			if current_chart:
				current_chart.raw_data += line + "\n"
				song.charts.push_back(current_chart)
				current_chart = Chart.new()
		
		if line.begins_with("#BMSCROLL"):
			current_chart.flags |= Chart.ChartFlags.BMSCROLL
		if line.begins_with("#HBSCROLL"):
			current_chart.flags |= Chart.ChartFlags.HBSCROLL
		
		if not chart_metadata:
			var header: PackedStringArray = _get_header(line)
			if header.size() != 2: continue
			var meta: String = header[0]
			var value: String = header[1]
			if value.is_empty(): continue
			match meta:
				"title":
					song.title = value
				"subtitle":
					song.subtitle = value
				"demostart":
					song.demo_start = float(value)
				"headscroll":
					song.head_scroll = float(value)
				"bpm":
					song.start_bpm = float(value)
				"offset":
					song.offset = float(value)
				"wave":
					song.wave_path = value
				"course":
					if value.is_valid_int():
						current_chart.course_type = int(value) as Chart.CourseType
					current_chart.course_type = Chart.CourseType.get(value.to_upper())
				"level":
					current_chart.level = int(value)
				"scoreinit":
					current_chart.score_init = int(value)
				"scorediff":
					current_chart.score_diff = int(value)
				"hiddenbranch":
					current_chart.hidden_branch = bool(int(value))
		else:
			current_chart.raw_data += line + "\n"
	
	return song

func _valid_note(c: String, count_empty: bool = false) -> Note.NoteType:
	if Note.NOTE_CHAR_TO_TYPE.has(c):
		if (not count_empty) and Note.NOTE_CHAR_TO_TYPE[c] == Note.NoteType.EMPTY:
			return Note.NoteType.NONE
		return Note.NOTE_CHAR_TO_TYPE[c]
	return Note.NoteType.NONE

func _parse_complex_number(s: String) -> PackedFloat64Array:
	var t: PackedFloat64Array = [0, 0]
	var current: String = ""
	for c in s:
		if c == "+" or c == "-":
			t[0] += current.to_float()
			current = c
		elif c == "i":
			# leniency when parsing complex: 1+i or 1-i allowed
			if current == "+" or current == "-" or current == "":
				current += "1"
			t[1] += current.to_float()
			current = ""
		else:
			current += c
	if current != "":
		t[0] += current.to_float()
	return t

enum MeasureBufferType {
	NOTE,
	BPMCHANGE,
	SCROLL,
	GOGOSTART,
	GOGOEND,
	DELAY
}

const FLUSH_HANDLED_COMMANDS: Dictionary[String, bool] = {
	"bpmchange": true,
	"scroll": true,
	"gogostart": true,
	"gogoend": true,
	"delay": true,
}

var bpm: float = 0
var time: float = 0
var meter: float = 4.0 * 4.0 / 4.0
var scroll: Vector2 = Vector2.RIGHT
var balloon_offset: int = 0
var note_index: int = 0
var barline_index: int = 0
var event_index: int = 0
		
var current_note: Note = null
var roll_head: Note = null
var roll_body: Note = null
var barlines: bool = true
var gogotime: bool = false

var last_measure_time: float = 0

func _parse_chart_data(song: Song, chart: Chart):
	bpm = song.start_bpm
	time = -song.offset
	meter = 4.0 * 4.0 / 4.0
	scroll = Vector2(song.head_scroll, 0)
	balloon_offset = 0
	note_index = 0
	barline_index = 0
	event_index = 0
	last_measure_time = time
	
	current_note = null
	roll_head = null
	roll_body = null
	barlines = true
	gogotime = false
		
	var measure_buffer: PackedStringArray
		
	var current_note_data: Array[Note] = chart.notes
	var current_barline_data: Array[Note] = chart.barlines
	var current_events: Array[Event] = chart.events
	var current_bpm_events: Array[Event] = chart.bpm_events
	var current_delays: Array[Event] = chart.delays
	
	var _push_barline: Callable = func():
		current_barline_data.push_back(Note.new(Note.NoteType.BARLINE, time, scroll, barline_index, not barlines))
		current_barline_data.back().bpm = bpm
		barline_index += 1
	
	var _push_event: Callable = func(type: Event.CommandType, value1: float = 0.0, value2: float = 0.0):
		var ev: Event = Event.new(type, time, value1, value2)
		ev.index = event_index
		event_index += 1
		current_events.push_back(ev)
		
	var _flush_measure: Callable = func():
		last_measure_time = time
		var note_count: int = 0
		var delays: float = 0
		var note_started: bool = false
		for buf in measure_buffer:
			if buf.begins_with("#"): continue
			note_count += 1
		for buf in measure_buffer:
			if buf.begins_with("#"):
				var c: PackedStringArray = _get_command(buf)
				if c.size() != 2: continue
				var command: String = c[0]
				var value: String = c[1]
				match command:
					"bpmchange":
						bpm = float(value)
						current_bpm_events.push_back(Event.new(Event.CommandType.BPMCHANGE, time, bpm))
					"scroll":
						if value.contains("i"):
							var complex: PackedFloat64Array = _parse_complex_number(value)
							scroll = Vector2(complex[0], complex[1])
						else:
							scroll = Vector2.RIGHT * value.to_float()
					"gogostart":
						gogotime = true
						_push_event.call(Event.CommandType.GOGOSTART)
					"gogoend":
						gogotime = false
						_push_event.call(Event.CommandType.GOGOEND)
					"delay":
						delays += value.to_float()
						# In TaikoJiro 1 & 2, the delay is inserted after the start of the last measure position.
						# TODO, this is probably not accurate- needs testing
						if song.compatibility_mode == Song.ChartCompatibility.JIRO1 or \
							song.compatibility_mode == Song.ChartCompatibility.JIRO2:
							current_bpm_events.push_back(Event.new(Event.CommandType.BPMCHANGE, last_measure_time, 0))
							current_delays.push_back(Event.new(Event.CommandType.DELAY, last_measure_time, value.to_float()))
							current_bpm_events.push_back(Event.new(Event.CommandType.BPMCHANGE, last_measure_time, bpm))
						else:
							current_bpm_events.push_back(Event.new(Event.CommandType.BPMCHANGE, time, 0))
							current_delays.push_back(Event.new(Event.CommandType.DELAY, time, value.to_float()))
							current_bpm_events.push_back(Event.new(Event.CommandType.BPMCHANGE, time, bpm))
			else:
				if not note_started:
					# Barline is only added upon the first definition of a note
					_push_barline.call()
					note_started = true
				if _valid_note(buf) > Note.NoteType.NONE:
					current_note = Note.new(_valid_note(buf), time, scroll, note_index)
					current_note.bpm = bpm
					if Note.NOTE_ROLL_HEADS.has(current_note.type):
						roll_head = current_note
					if current_note.type == Note.NoteType.END_ROLL and roll_head != null:
						current_note.roll_head = roll_head
						if roll_head.type == Note.NoteType.BALLOON:
							roll_head.end_time = time
						if roll_body:
							roll_body.roll_tail = current_note
							roll_body = null
						roll_head = null
					current_note_data.push_back(current_note)
					note_index += 1
					if Note.NOTE_ROLL_HEADS.has(current_note.type) and current_note.type != Note.NoteType.BALLOON:
						roll_body = Note.new(Note.NoteType.ROLL_BODY, time, scroll, note_index)
						roll_body.bpm = bpm
						roll_body.roll_head = current_note
						current_note_data.push_back(roll_body)
						note_index += 1
				time += (60 * (meter / note_count) / bpm) + delays
		if not note_started:
			_push_barline.call()
		if note_count == 0:
			time += (60 * meter / bpm) + delays
		measure_buffer.clear()
		
	for line in chart.raw_data.split("\n"):
		if line.is_empty(): continue
			
		if line.begins_with("#"):
			var c: PackedStringArray = _get_command(line)
			if c.size() != 2: continue
			var command: String = c[0]
			var value: String = c[1]
				
			# These guys will be dealt with later
			if FLUSH_HANDLED_COMMANDS.has(command):
				measure_buffer.push_back(line)
				continue
				
			match command:
				"measure":
					var split: PackedFloat64Array = value.split_floats("/")
					if split.size() != 2: continue
					meter = 4.0 * split[0] / split[1]
				"barlineoff":
					barlines = false
				"barlineon":
					barlines = true
				"end":
					_flush_measure.call()
					break
			
			continue
			
		for c in line:
			if _valid_note(c, true) != Note.NoteType.NONE:
				measure_buffer.push_back(c)
			if c == ",":
				_flush_measure.call()
	
	chart.notes.sort_custom(func(a: Note, b: Note):
		if a.time == b.time:
			return a.index > b.index
		return a.time > b.time
	)
	
	chart.events.sort_custom(func(a: Event, b: Event):
		if a.time == b.time:
			return a.index > b.index
		return a.time > b.time
	)
	
	for i in chart.notes.size():
		chart.notes[i].draw_index = i

func parse_tja_note_data(song: Song, chart_index: int = -1):
	if chart_index <= -1:
		print("Parsing all charts (This might take a while!)")
		for chart in song.charts:
			_parse_chart_data(song, chart)
		return
	if chart_index >= song.charts.size():
		print("chart_index is bigger than the amount of charts!")
		return
	_parse_chart_data(song, song.charts[chart_index])

func get_song_wave(song: Song) -> AudioStream:
	if song.wave_path.is_empty(): return null
	var full_path: String = song.path.get_base_dir() + "/" + song.wave_path
	var ext: String = song.wave_path.get_extension()
	match ext.to_lower():
		"ogg": return AudioStreamOggVorbis.load_from_file(full_path)
		"mp3": return AudioStreamMP3.load_from_file(full_path)
		"wav": return AudioStreamWAV.load_from_file(full_path)
	return null
