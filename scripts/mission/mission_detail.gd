class_name MissionDetail

var id: int;
var keyword: String;
var progress: int;
var max: int;
var description: String;
var onComplete: Callable;
var completed: bool

func _init(id: int,keyword: String, progress: int, max: int, desc: String, onComplete: Callable):
	self.id = id;
	self.keyword = keyword;
	self.progress = progress;
	self.max = max;
	description = desc;
	self.onComplete = onComplete;
	completed = progress == max;

func updateProgress(updateAmount: int):
	if (completed):
		return;
	
	progress = clamp(progress + updateAmount, 0, max);
	if(progress == max):
		completed = true;
		onComplete.call(id);
