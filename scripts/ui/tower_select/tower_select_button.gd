extends Button
class_name TowerSelectButton

const SKILL_BODY_BASE_FONT_SIZE := 13
const SKILL_BODY_MIN_FONT_SIZE := 9

var towerNameText: Label;
var evolutionNode: Node;
var evolutionCostText: Label;
var towerPortrait: TextureRect;

var towerClassImage: SynergyChipIcon;
var towerGenImage: SynergyChipIcon;
var synergiesNode: Control;

var statBlock: Control;
var atkLine: Label;
var rngLine: Label;
var asLine: Label;
var skillBox: Control;
var skillIcon: TextureRect;
var skillBody: RichTextLabel;

# Bumped per Setup; the async font-fit loop aborts when it moved (a Refresh
# re-runs Setup on this same node while a previous fit may still be awaiting).
var _fit_generation: int = 0

func _ready():
	add_to_group("tower_buttons")  # Ensures buttons register correctly

func Setup(p_name: String, sprite, towerClass: TowerTrait.TowerClass, towerGen: TowerTrait.TowerGeneration, level: int, evolutionCost: int):
	towerNameText = $TowerName
	evolutionCostText = $Evolution/EvolutionCost
	evolutionNode = $Evolution
	towerPortrait = $TowerPortrait
	towerClassImage = $Synergies/Class
	towerGenImage = $Synergies/Gen
	synergiesNode = $Synergies

	# An evolve card never shows a level number: the dealer-path evolve card
	# passes level = maxLevel + 1 (a level that does not exist), and the stats
	# panel precedent prints "Evolved", not a number.
	var name_suffix := ""
	if evolutionCost > 0:
		name_suffix = "  Evolve"
	elif level > 0:
		name_suffix = "  Lv." + str(level)
	towerNameText.text = p_name + name_suffix
	evolutionNode.visible = evolutionCost > 0
	evolutionCostText.text = " " + str(evolutionCost)
	if sprite != null:
		towerPortrait.texture = sprite
	else:
		var portrait = TowerCenter.getTowerPortraitByName(p_name.to_lower());
		if(portrait):
			towerPortrait.texture = portrait
	_setup_card_details(p_name, level, evolutionCost)
	# No real trait on either slot (deck-add popup cards) -> no synergy chip bar.
	synergiesNode.visible = TowerTrait.TOWER_CLASS_NAMES.has(towerClass) or TowerTrait.TOWER_GENERATION_NAMES.has(towerGen)
	if !synergiesNode.visible:
		return
	# Display names stay player-facing and may contain spaces ("Spell Caster");
	# the sprite key is normalised by ResourceManager, never by the caller.
	var classDisplayName = TowerTrait.TOWER_CLASS_NAMES.get(towerClass, "default");
	var genDisplayName = TowerTrait.TOWER_GENERATION_NAMES.get(towerGen, "default");
	var classSprite = ResourceManager.getSynergySprite(classDisplayName);
	var genSprite = ResourceManager.getSynergySprite(genDisplayName);
	if(towerClassImage):
		towerClassImage.texture = classSprite
		towerClassImage.set_synergy(towerClass, classDisplayName)

	if(towerGenImage):
		towerGenImage.texture = genSprite
		towerGenImage.set_synergy(towerGen, genDisplayName)

# Fills the TCG stat block (top-right) and skill box (bottom band) from the
# TowerCenter template - the card previews the state selecting it GRANTS.
func _setup_card_details(p_name: String, level: int, evolutionCost: int) -> void:
	statBlock = $StatBlock
	atkLine = $StatBlock/Rows/AtkLine
	rngLine = $StatBlock/Rows/RngLine
	asLine = $StatBlock/Rows/AsLine
	skillBox = $SkillBox
	skillIcon = $SkillBox/Entry/Icon
	skillBody = $SkillBox/Entry/Body

	_fit_generation += 1
	var fit_gen := _fit_generation
	# Reset before fitting: Setup re-runs on this same node on Refresh, so a
	# shrunken font would otherwise stick for every later card.
	_set_body_font_size(SKILL_BODY_BASE_FONT_SIZE)
	statBlock.visible = false
	skillBox.visible = false

	# Deck-add popup cards carry deck keys, not tower names -> lookup misses and
	# both sections stay hidden (same graceful-hide as the synergy chip bar).
	var entry = TowerCenter.getTowerDataByName(p_name)
	if entry == null or entry.data == null or entry.data.stats.is_empty():
		return
	var data: TowerData = entry.data

	var evolved := evolutionCost > 0
	# Dealer-path evolve cards arrive with level = maxLevel + 1 (no such stat
	# row); the clamp maps every input onto a real level - load-bearing.
	var target_level := clampi(level, 1, data.stats.size())

	# Read the template stat by index - never levelUp()/evolve()/getStat() on
	# the shared template (getStat reads its live _level, not the card's state).
	var stat: TowerStat = data.evolutionStat if evolved and data.evolutionStat != null else data.stats[target_level - 1]
	atkLine.text = "ATK " + str(stat.damage)
	rngLine.text = "RNG " + _format_number(stat.attackRange)
	asLine.text = "AS " + _format_number(stat.attackSpeed)
	atkLine.add_theme_color_override("font_color", UIPalette.attack_type_color(data.attackType))
	statBlock.visible = true

	# Main skill only (Director): the active slot, else the passive shown the
	# same way the stats panel does.
	var skill: Skill = data.evolutionSkill if evolved and data.evolutionSkill != null else data.skill
	var kind := "ACTIVE"
	if skill == null or skill.actions.is_empty():
		var passive_params: Dictionary = data.evolutionPassive if evolved and not data.evolutionPassive.is_empty() else data.passive
		skill = TowerDataLoader.build_passive_display_skill(passive_params)
		kind = "PASSIVE"
	if skill == null:
		return
	skillIcon.texture = TowerSkillIcon.resolve_icon_texture(skill)
	skillBody.text = _build_skill_bbcode(skill, kind, target_level)
	skillBox.visible = true
	_fit_body_font(fit_gen)

func _build_skill_bbcode(skill: Skill, kind: String, level: int) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]" + skill.get_display_name(level) + "[/b]  [color=" + TowerSkillIcon.KIND_COLOR + "]" + kind + "[/color]")
	# Bare tag list, same format as the stats-panel skill hover.
	if not skill.tags.is_empty():
		var tag_names: PackedStringArray = []
		for tag in skill.tags:
			tag_names.append(str(tag).capitalize().to_upper())
		lines.append("[color=" + TowerSkillIcon.DIM_COLOR + "]" + ", ".join(tag_names) + "[/color]")
	var desc := skill.get_display_desc(level, TowerSkillIcon.SCALING_COLOR)
	if desc != "":
		lines.append(desc)
	return "\n".join(lines)

# Fixed skill box (Director): a long desc steps the FONT down, never grows the
# box; clip_contents on the box is the final guard.
func _fit_body_font(fit_gen: int) -> void:
	var font_size := SKILL_BODY_BASE_FONT_SIZE
	while true:
		await get_tree().process_frame
		if not is_instance_valid(self) or not is_inside_tree() or fit_gen != _fit_generation:
			return
		if font_size <= SKILL_BODY_MIN_FONT_SIZE:
			return
		# 12 = the box StyleBox top+bottom content margins.
		if skillBody.get_content_height() <= skillBox.size.y - 12.0:
			return
		font_size -= 1
		_set_body_font_size(font_size)

func _set_body_font_size(p_size: int) -> void:
	skillBody.add_theme_font_size_override("normal_font_size", p_size)
	skillBody.add_theme_font_size_override("bold_font_size", p_size)

func _format_number(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	return "%.1f" % value
