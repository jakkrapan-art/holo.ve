extends Node
class_name YamlParser

##########
##Example Usage
##########

#var out_data = YamlParser.load_data("res://towers_data.yaml")

## If your YAML has multiple top-level sections:
#print(out_data.keys())  # ["towers", "characters", "levels", etc.]

## Access a section
#print(out_data["towers"])  # Dictionary of towers

## Example: Accessing a specific tower
#print(out_data["towers"]["ArrowTower"])

##########

static func load_data(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open YAML file: %s" % file_path)
		assert(false, "Critical: Could not open YAML file: %s" % file_path)
		return {}

	var lines = file.get_as_text().split("\n", false)
	var result: Dictionary = {}
	var stack: Array = [{ "dict": result, "indent": -1 }]
	var indent_unit_length: int = 0

	for line_number in range(lines.size()):
		var raw_line = lines[line_number]
		var trimmed_line = raw_line.strip_edges()

		if trimmed_line == "" or trimmed_line.begins_with("#"):
			continue

		# 🔥 Strict Check: No tabs for indentation
		var leading_indent = raw_line.substr(0, raw_line.length() - raw_line.lstrip(" ").length())
		if raw_line.find("\t") != -1 and leading_indent != "":
			var error_message = "YAML Error at line %d: Tabs used for indentation (not allowed)." % (line_number + 1)
			push_error(error_message)
			assert(false, error_message)

		# Indentation Level
		var indent_size = leading_indent.length()

		if indent_unit_length == 0 and indent_size > 0:
			# First indentation detected → set indent size
			indent_unit_length = indent_size

		if indent_unit_length > 0 and indent_size % indent_unit_length != 0:
			var error_message = "YAML Error at line %d: Indentation is not consistent." % (line_number + 1)
			push_error(error_message)
			assert(false, error_message)

		var level = 0
		if indent_unit_length > 0:
			level = indent_size / indent_unit_length

		# Parse key : value
		var key = ""
		var value = ""
		var inside_quotes = false
		var colon_index = -1

		for i in range(trimmed_line.length()):
			var c = trimmed_line[i]
			if c == '"':
				inside_quotes = !inside_quotes
			elif c == ':' and !inside_quotes:
				colon_index = i
				break

		if colon_index == -1:
			continue  # Not a key:value pair, skip

		key = trimmed_line.substr(0, colon_index).strip_edges()

		if key.find("\"") != -1:
			var error_message = "YAML Error at line %d: Invalid quoted key: %s" % [line_number + 1, key]
			push_error(error_message)
			assert(false, error_message)

		if colon_index + 1 >= trimmed_line.length():
			value = ""
		else:
			value = trimmed_line.substr(colon_index + 1).strip_edges()

		var final_value: Variant
		if value == "":
			final_value = {}
		else:
			final_value = _convert(value)

		# Correct Parent Stack
		while stack.size() > 0 and level <= stack[-1]["indent"]:
			stack.pop_back()

		var parent = stack[-1]["dict"]
		parent[key] = final_value

		if typeof(final_value) == TYPE_DICTIONARY:
			stack.append({ "dict": parent[key], "indent": level })

	return result

static func _convert(value: Variant) -> Variant:
	value = str(value).strip_edges()

	if value == "true":
		return true
	elif value == "false":
		return false
	elif value == "null" or value == "-":
		return null
	elif value.is_valid_int():
		return int(value)
	elif value.is_valid_float():
		return float(value)
	else:
		return value
