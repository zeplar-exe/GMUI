class_name TinyXMLParser extends RefCounted

var placeholder = '__default__'

static func convert_type(type):
	if type == 'Text':
		return 'Label'
	elif type == 'Widget':
		return 'Scene'
#	elif type == 'Row':
#		return 'HBoxContainer'
#	elif type == 'Column':
#		return 'VBoxContainer'
	else:
		return type

static func convert_prop_name(propName):
#	if propName == 'hint_text':
#		return 'placeholder_text'
#	else:
	return propName

static func parse_xml(content, isBuffer = false):
	var tree = _parse_xml(content, [], null, true, isBuffer)
	set_tree_parent(tree)
	var coll = collect_template(tree)
	put_temp_into_slot(tree, coll)
#	set_template(tree)
	set_tree_path(tree)
#	_set_scene_properties(tree)
	return tree

static func _parse_xml(content, paths = [], outerName = null, isRoot = false, isBuffer = false):
	var xmlParser = XMLParser.new()
	if isBuffer:
		xmlParser.open_buffer(content)
	else:
		xmlParser.open(content)
	var level = -1
	var treeRoot = null
	var pre = null
	var cur = null
#	paths = ['.']
	while xmlParser.read() == OK:
		var type = xmlParser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			level+=1
			var nodeType = xmlParser.get_node_name()
			var count = xmlParser.get_attribute_count()
			var newNode = TreeNode.new()
			newNode.type = convert_type(nodeType)
			if cur == null:
				treeRoot = newNode
				newNode.path = '.'
				newNode.isRoot = isRoot
				newNode.name = str(randi())
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
					if attrName.contains('g-bind:'):
						var value = attrValue
						if value == null:
							newNode.bindDict[attrName.split(':')[1]] = attrValue
						else:
							attrName = convert_prop_name(attrName)
							newNode.properties[attrName] = attrValue
					elif attrName == 'ref':
						newNode.ref['name'] = attrValue
					else:
						attrName = convert_prop_name(attrName)
						newNode.properties[attrName] = attrValue
					set_align(newNode, nodeType, attrName, attrValue)
				var builtinNames = FileUtils.get_all_file('res://addons/gmui/ui/scenes')
				newNode.isBuiltComponent = builtinNames.find('res://addons/gmui/ui/scenes/' + nodeType + '.tscn') != -1
#				paths = ['.']
			elif nodeType == 'Scene':
				newNode.name = str(randi())
				var sceneXML = null
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
#					if attrName == 'name':
					if attrName == 'scenePath':
						var xmlPath = attrValue.replace('.gmui', '.xml')
						xmlPath = attrValue.replace('res://dist/components', 'res://dist/layouts/components').replace('.gmui', '.xml')
						newNode.sceneXMLPath = xmlPath
						newNode.isScene = true
						newNode.sceneXML = _parse_xml(xmlPath, paths, newNode.name, false)
						newNode.sceneXML.name = newNode.name
						sceneXML = newNode.sceneXML
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
					if attrName.contains('g-bind:'):
						attrName = convert_prop_name(attrName)
						newNode.staticProps[attrName] = attrValue
					elif attrName == 'ref':
						newNode.sceneXML.ref['name'] = attrValue
					elif attrName == 'id':
						newNode.sceneXML.id['name'] = attrValue
					elif attrName == 'g-model':
						newNode.modelName = attrValue
					else:
						attrName = convert_prop_name(attrName)
						newNode.staticProps[attrName] = attrValue
			elif nodeType == 'Template':
				var hasName = false
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
					if attrName == 'slot':
						hasName = true
						newNode.name = attrValue
				if !hasName:
					newNode.name = '__default__'
				newNode.isTemplate = true
			elif nodeType == 'Slot':
				var hasName = false
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
					if attrName == 'name':
						hasName = true
						newNode.name = attrValue
				if !hasName:
					newNode.name = '__default__'
				newNode.isSlot = true
			elif nodeType in ['LineEdit', 'TextEdit', 'CodeEdit']:
				ControlStrategy.new(newNode, 'text', xmlParser).operate()
			elif nodeType in ['TabBar', 'TabContainer']:
				ControlStrategy.new(newNode, 'current_tab', xmlParser).operate()
			elif nodeType == 'ColorPicker':
				ControlStrategy.new(newNode, 'color', xmlParser).operate()
			elif nodeType in ['CheckButton', 'CheckBox']:
				ControlStrategy.new(newNode, 'button_pressed', xmlParser).operate()
			elif nodeType == 'SpinBox':
				ControlStrategy.new(newNode, 'value', xmlParser).operate()
			elif nodeType == 'OptionButton':
				ControlStrategy.new(newNode, 'selected', xmlParser).operate()
			else:
				var builtinNames = FileUtils.get_all_file('res://addons/gmui/ui/scenes')
				newNode.isBuiltComponent = builtinNames.find('res://addons/gmui/ui/scenes/' + nodeType + '.tscn') != -1
				newNode.name = str(randi())
				for i in count:
					var attrName = xmlParser.get_attribute_name(i)
					var attrValue = xmlParser.get_attribute_value(i)
					if attrName.contains('g-bind:'):
						attrName = convert_prop_name(attrName)
						var expression = Expression.new()
						var res = expression.parse(attrValue)
						if res == OK:
							var value = expression.execute()
							newNode.properties[attrName.split(':')[1]] = value
						else:
							newNode.properties[attrName.split(':')[1]] = attrValue
					elif attrName == 'ref':
						newNode.ref['name'] = attrValue
					elif attrName == 'id':
						newNode.id['name'] = attrValue
					else:
						attrName = convert_prop_name(attrName)
						newNode.properties[attrName] = attrValue
					set_align(newNode, nodeType, attrName, attrValue)
			if cur != null:
				cur.children.append(newNode)
				newNode.parent = cur
				
#			if outerName != null:
#				paths.push_back(outerName)
#				outerName = null
#			else:
#				paths.push_back(newNode.name)

#			var tempPaths = paths.duplicate(true)
#			tempPaths.remove_at(0)
#			if tempPaths.is_empty():
#				newNode.path = '.'
#			else:
#				newNode.path = '.'.path_join('/'.join(tempPaths))
			cur = newNode
#			print(newNode.type, newNode.path)
		elif type == XMLParser.NODE_ELEMENT_END:
			cur = cur.parent
#			paths.pop_back()
	return treeRoot

static func _set_scene_properties(ast):
	if ast.isScene:
		ast.sceneXML.properties = ast.properties
	for child in ast.children:
		_set_scene_properties(child)

static func set_tree_parent(node, parent = null):
	node.parent = parent
	if node.isScene:
		set_tree_parent(node.sceneXML, node.parent)
	for child in node.children:
		set_tree_parent(child, node)

static func set_tree_path(node, parent = null, path = '.'):
	if node.isScene:
		node.path = path.path_join(node.name)
		set_tree_path(node.sceneXML, node.parent, path)
	elif node.isSlot:
		var template = node.template
		if template != null:
			for child in template.children:
				set_tree_path(child, node.parent, path)
	else:
		if parent != null:
			path = path.path_join(node.name)
		node.path = path
		for child in node.children:
			set_tree_path(child, node, path)

static func put_temp_into_slot(node, coll = {}):
	if node.isSlot and coll.has(node.name):
		node.template = coll[node.name]
#		coll[node.path].parent.children.erase(coll[node.path])
	elif node.isScene:
		for child in node.sceneXML.children:
			put_temp_into_slot(child, coll)
	for child in node.children:
		put_temp_into_slot(child, coll)

static func collect_template(node, coll = {}):
	if node.isTemplate:
		coll[node.name] = node
		if node.isScene:
			for child in node.sceneXML.children:
				collect_template(child, coll)
		node.parent.children = []
	else:
		for child in node.children:
			collect_template(child, coll)
	return coll
	
static func get_offset_by_node_path(content, nodePath, isBuffer = false):
	var xmlParser = XMLParser.new()
	if isBuffer:
		xmlParser.open_buffer(content)
	else:
		xmlParser.open(content)
	var names = []
	var start = -1
	var end = -1
	var level = -1
	while xmlParser.read() == OK:
		level += 1
		var type = xmlParser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			var nodeType = xmlParser.get_node_name()
			var count = xmlParser.get_attribute_count()
			for i in count:
				var attrName = xmlParser.get_attribute_name(i)
				var attrValue = xmlParser.get_attribute_value(i)
				if attrName == 'name':
					if level == 0:
						names.push_front('.')
					else:
						names.push_frontattrValue
					names.reverse()
					if '/'.join(names) == nodePath:
						start = xmlParser.get_node_offset()
					names.reverse()
		elif type == XMLParser.NODE_ELEMENT_END:
			names.reverse()
			if '/'.join(names) == nodePath:
				end = xmlParser.get_node_offset()
				return [start, end]
			names.reverse()
			names.pop_front()

static func append(content, tag, nodePath, isBuffer = false):
	var xmlParser = XMLParser.new()
	var bytes = null
	if isBuffer:
		xmlParser.open_buffer(content)
		bytes = content
	else:
		xmlParser.open(content)
		bytes = FileAccess.get_file_as_bytes(content)
	var text = bytes.get_string_from_utf8()
	var names = []
	var start = -1
	var end = -1
	var level = -1
	var tabCount:int = nodePath.count('/') + 1
	for i in tabCount:
		tag = tag.insert(0, '	')
	tag = tag.insert(0, '\n')
	while xmlParser.read() == OK:
		var type = xmlParser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			level += 1
			var nodeType = xmlParser.get_node_name()
			var count = xmlParser.get_attribute_count()
			for i in count:
				var attrName = xmlParser.get_attribute_name(i)
				var attrValue = xmlParser.get_attribute_value(i)
				if attrName == 'name':
					if level == 0:
						names.append('.')
					else:
						names.push_frontattrValue
					start = xmlParser.get_node_offset()
		elif type == XMLParser.NODE_ELEMENT_END:
			names.reverse()
			if '/'.join(names) == nodePath:
				end = xmlParser.get_node_offset()
				var endTag = '</%s>' % xmlParser.get_node_name()
				var endTagBuff = endTag.to_utf8_buffer()
				var oldEndTagBuff = bytes.slice(end, end + endTagBuff.size())
				if endTagBuff == oldEndTagBuff:
					tag = tag.insert(tag.length(), '\n')
					for i in tabCount - 1:
						tag = tag.insert(tag.length(), '	')
			names.reverse()
			names.pop_front()	
	var tagBuff = tag.to_utf8_buffer()
	var newBytes = bytes.slice(0, end)
	newBytes.append_array(tagBuff)
	newBytes.append_array(bytes.slice(end, bytes.size()))
	if isBuffer:
		return newBytes
	else:
		var file = FileAccess.open(content, FileAccess.WRITE)
		file.store_buffer(newBytes)
		file.close()

static func set_align(newNode, nodeType, attrName, attrValue):
	var methodName = 'set_anchors_and_offsets_preset'
	if nodeType == 'Column':
		if attrName == 'align':
			match attrValue:
				'center':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER]
						}
					)
				'top':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER_TOP]
						}
					)
				'bottom':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER_BOTTOM]
						}
					)
	elif nodeType == 'Row':
		if attrName == 'align':
			match attrValue:
				'center':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER]
						}
					)
				'left':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER_LEFT]
						}
					)
				'right':
					newNode.commands.append(
						{
							'methodName': methodName,
							'args': [Control.PRESET_CENTER_RIGHT]
						}
					)
