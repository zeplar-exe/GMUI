@tool
class_name Plugin extends EditorPlugin

var editorInterface = get_editor_interface()
var editorSetting = editorInterface.get_editor_settings()
var scriptEditor = editorInterface.get_script_editor()
var fileSystem = editorInterface.get_file_system_dock()
var editObj = null
var editorDict = {}
var xmlDict = {}
var xmlContent = {}
var isSyncToScene = false
var dock = preload("res://addons/gmui/scenes/layout_option.tscn").instantiate()
var genBtn = dock.get_node('./GenFileBtn')
@onready var vms = Engine.get_singleton('_vms')
@onready var patch = Engine.get_singleton('_patch')

signal bue_setted

func _enter_tree():
	var _vms_ = preload('res://addons/gmui/scripts/common/vms.gd').new()
	var _patch_ = preload('res://addons/gmui/scripts/vnode/patch.gd').new()
	var _values_ = preload('res://addons/gmui/scripts/observer/values.gd').new()
	Engine.register_singleton('_vms', _vms_)
	Engine.register_singleton('_patch', _patch_)
	Engine.register_singleton('_values', _values_)
	add_autoload_singleton('_vms', 'res://addons/gmui/scripts/common/vms.gd')
	add_autoload_singleton('_values', 'res://addons/gmui/scripts/observer/values.gd')
	add_autoload_singleton('_patch', 'res://addons/gmui/scripts/vnode/patch.gd')
	editorSetting.set('docks/filesystem/textfile_extensions', 'txt,md,cfg,ini,log,json,yml,yaml,toml,xml,gmui')
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, dock)
#	scene_changed.connect(set_bue)
#	scene_changed.connect(init_node)
#	scene_changed.connect(set_xml_content)
#	scene_changed.connect(bind_load_xml_signal)
	genBtn.pressed.connect(gen)
	gen()
	DirAccess.make_dir_absolute('res://components')
	DirAccess.make_dir_absolute('res://pages')
	DirAccess.make_dir_absolute('res://scripts')
	DirAccess.make_dir_absolute('res://dist/scenes')
	DirAccess.make_dir_absolute('res://dist')
	add_custom_type('GNode', 'Node', preload('res://addons/gmui/scripts/common/gnode.gd'), preload('res://addons/gmui/icon/Node.svg'))
	add_custom_type('GNode2D', 'Node2D', preload('res://addons/gmui/scripts/common/gnode_2d.gd'), preload('res://addons/gmui/icon/Node2D.svg'))
	add_custom_type('GNode3D', 'Node3D', preload('res://addons/gmui/scripts/common/gnode_3d.gd'), preload('res://addons/gmui/icon/Node3D.svg'))
	add_custom_type('GControl', 'Control', preload('res://addons/gmui/scripts/common/gcontrol.gd'), preload('res://addons/gmui/icon/Control.svg'))
#func _ready():
#	print('plugin ready')

func _build():
	add_autoload_singleton('_vms', 'res://addons/gmui/scripts/common/vms.gd')
	add_autoload_singleton('_values', 'res://addons/gmui/scripts/observer/values.gd')
	add_autoload_singleton('_patch', 'res://addons/gmui/scripts/vnode/patch.gd')
	gen()
	return true

func set_xml_content(rootNode):
	var scenePath = rootNode.scene_file_path
	var xmlPath = FileUtils.scene_to_xml_path(scenePath)
	if !xmlContent.has(xmlPath):
		xmlContent[xmlPath] = FileAccess.get_file_as_string(xmlPath)

#func set_bue(rootNode):
#	if !vms.bueDict.has(vms.get_id()):
#		vms.bueDict[vms.get_id()] = Bue.new({ })
#	emit_signal('bue_setted')
	
func init_node(rootNode):
	if rootNode == null or (vms.isInited.has(rootNode.scene_file_path) and vms.isInited[rootNode.scene_file_path]): 
		return
	vms.isInited[rootNode.scene_file_path] = true
	bind_child_entered_signal(rootNode)
	
#func init_scene(rootNode):
#	if rootNode == null or (vms.isInited.has(rootNode.scene_file_path) and vms.isInited[rootNode.scene_file_path]): 
#		return
#	vms.isInited[rootNode.scene_file_path] = true
#	var scenePath = rootNode.scene_file_path
#	var xmlPath = FileUtils.scene_to_xml_path(scenePath)
#	var vnode = VNodeHelper.create_vnodes(ast, vm)
#	remove_all_child(rootNode)
#	patch.run(rootNode, vnode)
#	bind_child_entered_signal(rootNode)

func remove_all_child(node):
#	node.child_entered_tree.disconnect(child_added.bind(node))
	for child in node.get_children():
		remove_all_child(child)
		node.remove_child(child)
#		child.owner = null
		child.queue_free()

func bind_child_entered_signal(node):
	node.child_entered_tree.connect(add_xml_node.bind(node))
	for child in node.get_children():
		bind_child_entered_signal(child)

func add_xml_node(node, parent):
	if !isSyncToScene and Engine.is_editor_hint():
		var owner = PathUtils.get_owner(parent)
		if !vms.isInited[owner.scene_file_path]: return
		var xmlPath = FileUtils.scene_to_xml_path(owner.scene_file_path)
		TinyXMLParser.append(xmlPath, '<%s name="%s"></%s>' % [node.get_class(), node.name, node.get_class()], PathUtils.get_node_path(parent))
		if editorDict.has(xmlPath):
			editorDict[xmlPath].text = FileAccess.get_file_as_string(xmlPath)

#func _apply_changes():
#	if editObj is Node:
#		pass
#	elif editObj is Resource:
#		pass
#	pass
#
#func _handles(object):
#	if object is Node or object is Resource:
#		return true
#	else:
#		return false
#
#func _edit(object):
#	if object != null:
#		editObj = object
#		if object is Resource and object.resource_path.get_extension() == 'xml':
#			if !editorDict.has(object.resource_path):
#				var codeEdit = scriptEditor.get_current_editor().get_base_editor()
#				editorDict[object.resource_path] = codeEdit
#				xmlDict[codeEdit.get_instance_id()] = object.resource_path

func _save_external_data():
	if editObj is Resource and editObj.resource_path.get_extension() == 'xml':
#		print('xml')
#		xml_to_scene()
		pass
	elif editObj is Node:
#		print('node')
		pass

#func xml_to_scene():
#	isSyncToScene = true
#	var codeEdit = scriptEditor.get_current_editor().get_base_editor()
#	var scenePath = FileUtils.xml_to_scene_path(editObj.resource_path)
#	var scene = load(scenePath)
#	var rootNode = scene.instantiate()
#	if xmlDict.has(codeEdit.get_instance_id()):
#		var xmlPath = xmlDict[codeEdit.get_instance_id()]
#		var ast = TinyXMLParser.parse_xml(xmlPath)
#		var code = CodeGen.render_func(ast, {})
#		var renderFunc = Function.new(code, vh)
#		var newVNode = renderFunc.exec()
#		var oldVNode = vh.rtree_to_vtree(rootNode)
#		patch.run(oldVNode, newVNode)
#		set_all_owner(rootNode, newVNode.rnode)
#		scene.pack(rootNode)
#		ResourceSaver.save(scene, scenePath)
#		editorInterface.reload_scene_from_path(scenePath)
#	isSyncToScene = false

func set_all_owner(rootNode, node):
	for child in node.get_children():
		set_all_owner(rootNode, child)
	node.owner = rootNode

func _get_plugin_name():
	return 'GMUI'

func mount_script():
	var scriptPaths = FileUtils.get_all_file('res://scripts')
	for scriptPath in scriptPaths:
		var script = load(scriptPath).instantiate()
		var scene = PackedScene.new()
		var root = Control.new()
		root.set_script(script)
		scene.pack(root)
		ResourceSaver.save(scene, scriptPath.replace('res://scripts', 'res://dist/scenes'))

func gen_scene(type):
	var filePaths = FileUtils.get_all_file('res://' + type)
	for filePath in filePaths:
		var content = FileAccess.get_file_as_string(filePath)
		var regex = RegEx.new()
		regex.compile('<script>(.|\n)*</script>')
		var regexMatchs = regex.search_all(content)
		if regexMatchs != null and regexMatchs.size() > 0:
			for regexMatch in regexMatchs:
				content = content.replace(regexMatch.strings[0], '')
		content = content.replace('scenePath="res://components', 'scenePath="res://dist/components')
		content = content.replace('<template>', '').replace('</template>', '')
		var rootType = ''
		var xmlPath = filePath.replace('res://' + type, 'res://dist/layouts/' + type)
		xmlPath = xmlPath.trim_suffix('gmui') + 'xml'
		var scenePath = xmlPath.replace('res://dist/layouts', 'res://dist/scenes')
		scenePath = scenePath.replace('.xml', '.tscn')
		var xmlDirPath = xmlPath.get_base_dir()
		regex.compile('[^</>]\\w*[^</>]')
		var regexMatch = regex.search(content)
		if regexMatch != null and regexMatch.strings.size() > 0:
			rootType = regexMatch.strings[0].replace(' ', '')
			content = '<?xml version="1.0" encoding="UTF-8"?>\n' + content
			DirAccess.make_dir_recursive_absolute(xmlDirPath)
			var file = FileAccess.open(xmlPath, FileAccess.WRITE)
			file.store_string(content)
			file.close()
			var scene = PackedScene.new()
			var root = ClassDB.instantiate(rootType)
			root.name = 'Root'
			gen_super_script(rootType)
			var scriptPath = gen_script(filePath, scenePath, rootType)
			var script = load(scriptPath)
			root.set_script(script)
			scene.pack(root)
			DirAccess.make_dir_recursive_absolute(scenePath.get_base_dir())
			ResourceSaver.save(scene, scenePath)
		else:
			DirAccess.make_dir_recursive_absolute(scenePath.get_base_dir())
			var scene = PackedScene.new()
			var root = Control.new()
			root.name = 'Root'
			scene.pack(root)
			ResourceSaver.save(scene, scenePath)
			DirAccess.make_dir_recursive_absolute(xmlPath.get_base_dir())
			FileAccess.open(xmlPath, FileAccess.WRITE).close()
		
func gen():
	gen_scenes()

func gen_scenes():
	gen_scene('components')
	gen_scene('pages')

#func gen_scripts():
#	var arr = gen_script('components')
#	arr.append_array(gen_script('pages'))
#	return arr

func gen_super_script(nodeType):
	var superScript = preload('res://addons/gmui/scripts/common/gcontrol.gd')
	superScript.source_code = superScript.source_code.replace('extends Control', 'extends ' + nodeType)
	DirAccess.make_dir_recursive_absolute('res://dist/super_scripts')
	ResourceSaver.save(superScript, 'res://dist/super_scripts/' + nodeType + '.gd')
	superScript.source_code = superScript.source_code.replace('extends ' + nodeType, 'extends Control')
		
func gen_script(gmuiFile, scenePath, nodeType):
	var scriptPath = scenePath.replace('res://dist/scenes', 'res://dist/scripts')
	var content = FileAccess.get_file_as_string(gmuiFile)
	var regex = RegEx.new()
	regex.compile('<script>(.|\n)*</script>')
	var regexMatch = regex.search(content)
	var scriptDirPath = scriptPath.get_base_dir()
	var distScriptPath = scriptPath.trim_suffix('tscn') + 'gd'
	if regexMatch != null and regexMatch.strings.size() > 0:
		var scriptContent = regexMatch.strings[0]
		scriptContent = scriptContent.lstrip('<script>\n').rstrip('\n</script>')
		scriptContent = '	extends "res://dist/super_scripts/%s.gd"\n' % nodeType + scriptContent
		regex.compile('\n*\t+.*\n*')
		regexMatch = regex.search_all(scriptContent)
		var standardContent = ''
		for matchs in regexMatch:
			standardContent += matchs.strings[0].substr(1)
		DirAccess.make_dir_recursive_absolute(scriptDirPath)
		var file = FileAccess.open(distScriptPath, FileAccess.WRITE)
		file.store_string(standardContent)
		file.close()
	else:
		DirAccess.make_dir_recursive_absolute(distScriptPath.get_base_dir())
		var file = FileAccess.open(distScriptPath, FileAccess.WRITE)
		file.store_string('extends "res://addons/gmui/scripts/common/gcontrol.gd"')
		file.close()
	return distScriptPath

#func gen_script(type, nodeType):
#	var scriptPaths = []
#	var filePaths = FileUtils.get_all_file('res://' + type)
#	for filePath in filePaths:
#		var content = FileAccess.get_file_as_string(filePath)
#		var regex = RegEx.new()
#		regex.compile('<script>(.|\n)*</script>')
#		var regexMatch = regex.search(content)
#		var scriptPath = filePath.replace('res://' + type, 'res://dist/scripts/' + type)
#		var scriptDirPath = scriptPath.get_base_dir()
#		var distScriptPath = scriptPath.trim_suffix('gmui') + 'gd'
#		if regexMatch != null and regexMatch.strings.size() > 0:
#			var scriptContent = regexMatch.strings[0]
#			scriptContent = scriptContent.lstrip('<script>\n').rstrip('\n</script>')
#			scriptContent = '	extends "res://dist/super_scripts/%s.gd"\n' % nodeType + scriptContent
#			regex.compile('\n*\t+.*\n*')
#			regexMatch = regex.search_all(scriptContent)
#			var standardContent = ''
#			for matchs in regexMatch:
#				standardContent += matchs.strings[0].substr(1)
#			DirAccess.make_dir_recursive_absolute(scriptDirPath)
#			var file = FileAccess.open(distScriptPath, FileAccess.WRITE)
#			file.store_string(standardContent)
#			file.close()
#		else:
#			DirAccess.make_dir_recursive_absolute(distScriptPath.get_base_dir())
#			var file = FileAccess.open(distScriptPath, FileAccess.WRITE)
#			file.store_string('extends "res://addons/gmui/scripts/common/gcontrol.gd"')
#			file.close()
#		scriptPaths.append(distScriptPath)
#	return scriptPaths
#		FileAccess.open()
#func gen_gmui():
#	var xmlPaths = FileUtils.get_all_file('res://layoutss')
#	for xmlPath in xmlPaths:
#		var xmlParser = XMLParser.new()
#		xmlParser.open(xmlPath)
#		while xmlParser.read():

func _exit_tree():
	vms.isInited.clear()
#	scene_changed.disconnect(set_bue)
#	scene_changed.disconnect(init_node)
	remove_control_from_docks(dock)
	Engine.unregister_singleton('_vms')
	Engine.unregister_singleton('_patch')
	Engine.unregister_singleton('_values')
	remove_autoload_singleton('_vms')
	remove_autoload_singleton('_patch')
	remove_autoload_singleton('_values')
	remove_custom_type('RootNode')
