extends EditorInspectorPlugin

func _can_handle(object):
	return object is MapData
	
func _parse_begin(object):
	add_custom_control(create_grid_ui(object))

func create_grid_ui(object):
	var vbox = VBoxContainer.new();
	
	var title = Label.new();
	title.set_text("Path");
	vbox.add_child(title);
	
	var grid = GridContainer.new();
	
	grid.columns = 11;
	var rows = 11;
	var curIndx = 0;
	for y in range(rows):
		for x in range(grid.columns):
			var checkBox = PathCheckBox.new(self, curIndx);
			checkBox.connect("onToggle", Callable(self, "onCheckboxToggled"))
			grid.add_child(checkBox);
			
			curIndx += 1;
	
	vbox.add_child(grid);
	return vbox

func onCheckboxToggled(checked, index, object: MapData):
	object.path[index] = checked
