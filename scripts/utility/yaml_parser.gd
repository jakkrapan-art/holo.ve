extends Node
class_name YamlParser

# ----------------------------
# Main entry
# ----------------------------
static func load_data(file_path: String) -> Variant:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		push_error("Failed to open YAML file: %s" % file_path)
		return {}

	var lines: PackedStringArray = f.get_as_text().split("\n", false)

	# Determine root type: Array if first line starts with "-", else Dictionary
	var first_idx := _next_sig_index(lines, -1)
	if first_idx == -1:
		return {}
	var first_trim := _trim_comment(lines[first_idx]).strip_edges()
	var root: Variant
	if first_trim.begins_with("-"):
		root = []
	else:
		root = {}

	var stack: Array = [{ "container": root, "indent": -1 }]
	var indent_unit: int = 0

	for i in range(lines.size()):
		var raw: String = lines[i]
		var trimmed: String = _trim_comment(raw).strip_edges()
		if trimmed == "":
			continue

		# --- indentation
		if raw.find("\t") != -1:
			_fail(i, "Tabs used for indentation (not allowed).")
		var indent_spaces := _count_leading_spaces(raw)
		if indent_unit == 0 and indent_spaces > 0:
			indent_unit = indent_spaces
		if indent_unit > 0 and indent_spaces % indent_unit != 0:
			_fail(i, "Indentation is not consistent.")
		var level := 0
		if indent_unit > 0:
			level = indent_spaces / indent_unit

		# Unwind stack to correct parent
		while stack.size() > 0 and level <= stack[-1]["indent"]:
			stack.pop_back()
		var parent: Variant = stack[-1]["container"]

		# --- list item
		if trimmed.begins_with("-"):
			var after_dash: String = trimmed.substr(1).strip_edges()

			if typeof(parent) != TYPE_ARRAY:
				_fail(i, "List item '-' under a non-list parent. Check indentation and previous 'key:' line.")

			if after_dash == "":
				var next_info := _peek_child(lines, i, indent_spaces)
				var item_val: Variant
				if next_info["is_list"]:
					item_val = []
				else:
					item_val = {}
				parent.append(item_val)
				stack.append({ "container": item_val, "indent": level })
				continue

			if _has_unquoted_colon(after_dash):
				var kv := _split_kv(after_dash)
				var item_dict: Dictionary = {}
				var val: Variant
				if kv["value"] == "":
					var next_info2 := _peek_child(lines, i, indent_spaces)
					if next_info2["is_list"]:
						val = []
					else:
						val = {}
				else:
					val = _convert(kv["value"])
				item_dict[kv["key"]] = val
				parent.append(item_dict)
				stack.append({ "container": item_dict, "indent": level })
				if typeof(val) in [TYPE_DICTIONARY, TYPE_ARRAY]:
					stack.append({ "container": val, "indent": level + 1 })
			else:
				parent.append(_convert(after_dash))
			continue

		# --- dictionary entry
		if not _has_unquoted_colon(trimmed):
			continue
		var kv2 := _split_kv(trimmed)
		var value: Variant
		if kv2["value"] == "":
			var next_info3 := _peek_child(lines, i, indent_spaces)
			if next_info3["is_list"]:
				value = []
			else:
				value = {}
		else:
			value = _convert(kv2["value"])

		if typeof(parent) == TYPE_DICTIONARY:
			parent[kv2["key"]] = value
		elif typeof(parent) == TYPE_ARRAY:
			if parent.size() == 0 or typeof(parent[-1]) != TYPE_DICTIONARY:
				parent.append({})
			parent[-1][kv2["key"]] = value
			parent = parent[-1]

		if typeof(value) in [TYPE_DICTIONARY, TYPE_ARRAY]:
			stack.append({ "container": value, "indent": level })

	return root


# ----------------------------
# Helpers
# ----------------------------
static func _fail(line_idx: int, msg: String) -> void:
	var text := "YAML Error at line %d: %s" % [line_idx + 1, msg]
	push_error(text)
	assert(false, text)


static func _trim_comment(line: String) -> String:
	var out := ""
	var in_s := false
	var in_d := false
	for i in range(line.length()):
		var ch := line.substr(i, 1)
		if ch == "'" and not in_d:
			in_s = not in_s
		elif ch == '"' and not in_s:
			in_d = not in_d
		elif ch == "#" and not in_s and not in_d:
			break
		out += ch
	return out


static func _count_leading_spaces(s: String) -> int:
	var n := 0
	for i in range(s.length()):
		if s.substr(i, 1) == " ":
			n += 1
		else:
			break
	return n


static func _next_sig_index(lines: PackedStringArray, start_idx: int) -> int:
	for j in range(start_idx + 1, lines.size()):
		var t := _trim_comment(lines[j]).strip_edges()
		if t != "":
			return j
	return -1


static func _peek_child(lines: PackedStringArray, cur_idx: int, cur_indent_spaces: int) -> Dictionary:
	var j := cur_idx + 1
	while j < lines.size():
		var raw := lines[j]
		var trimmed := _trim_comment(raw).strip_edges()
		if trimmed == "":
			j += 1
			continue
		var indent_spaces := _count_leading_spaces(raw)
		if indent_spaces <= cur_indent_spaces:
			return { "is_list": false }
		return { "is_list": trimmed.begins_with("-") }
	return { "is_list": false }


static func _has_unquoted_colon(s: String) -> bool:
	var in_s := false
	var in_d := false
	for i in range(s.length()):
		var ch := s.substr(i, 1)
		if ch == "'" and not in_d:
			in_s = not in_s
		elif ch == '"' and not in_s:
			in_d = not in_d
		elif ch == ":" and not in_s and not in_d:
			return true
	return false


static func _split_kv(s: String) -> Dictionary:
	var in_s := false
	var in_d := false
	for i in range(s.length()):
		var ch := s.substr(i, 1)
		if ch == "'" and not in_d:
			in_s = not in_s
		elif ch == '"' and not in_s:
			in_d = not in_d
		elif ch == ":" and not in_s and not in_d:
			var key := s.substr(0, i).strip_edges()
			var val := s.substr(i + 1).strip_edges()
			return { "key": key, "value": val }
	return { "key": s.strip_edges(), "value": "" }


static func _convert(v: String) -> Variant:
	var s := v.strip_edges()
	if s == "true":
		return true
	if s == "false":
		return false
	if s == "null" or s == "~" or s == "-":
		return null
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		return float(s)
	if s.length() >= 2:
		var a := s.substr(0, 1)
		var b := s.substr(s.length() - 1, 1)
		if (a == '"' and b == '"') or (a == "'" and b == "'"):
			return s.substr(1, s.length() - 2)
	return s
