class_name MissionDetail

var id: int;
var keyword: String;
var progress: int;
var maxProgress: int;
var description: String;
var onComplete: Callable;
var completed: bool

func _init(p_id: int,p_keyword: String, p_progress: int, p_max: int, desc: String, p_onComplete: Callable):
	self.id = p_id;
	self.keyword = p_keyword;
	self.progress = p_progress;
	self.maxProgress = p_max;
	description = desc;
	self.onComplete = p_onComplete;
	completed = p_progress == p_max;

func updateProgress(updateAmount: int):
	if (completed):
		return;
	
	progress = clamp(progress + updateAmount, 0, maxProgress);
	if(progress == maxProgress):
		completed = true;
		onComplete.call(id);
