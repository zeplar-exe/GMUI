@tool
extends Node

var initDict = {}

func run(oldVNode, newVNode):
	if oldVNode is Node:
		_create_rnode_tree(oldVNode, newVNode)
	else:
		if !_is_same_node(oldVNode, newVNode):
			if oldVNode.rnode != Engine.get_main_loop().current_scene:
				var newRoot = _create_rnode_tree_with_root(null, newVNode)
	#			set_all_owner(PathUtils.get_owner(oldVNode.rnode), newRoot)
				oldVNode.rnode.replace_by(newRoot)
				newVNode.rnode = newRoot
				return newVNode
			else:
				push_error('The root node cannot be replaced')
		_patch_properties(oldVNode, newVNode)
#		bind_model(oldVNode.rnode, newVNode)
		if oldVNode.children.size() > 0 and newVNode.children.size() > 0:
			_updateChildren(oldVNode.rnode, oldVNode.children, newVNode.children)
		elif oldVNode.children.size() > 0:
			_remove_all_child(oldVNode.rnode)
#			__remove_all_child_vnode(oldVNode)
		elif newVNode.children.size() > 0:
			_create_rnode_tree(oldVNode.rnode, newVNode)
#			_add_all_child_vnode(oldVNode, newVNode)
		newVNode.rnode = oldVNode.rnode
	return newVNode
		
func _add_rnode_by_vnode(rnode, vnode, vmRoot = null, mode = Node.INTERNAL_MODE_DISABLED):
	var newRNode = null
	if vnode.isScene:
		var scene = load(FileUtils.xml_to_scene_path(vnode.sceneXMLPath))
		newRNode = scene.instantiate()
#		dont_init(newRNode)
		rnode.add_child(newRNode)
	elif vnode.isBuiltComponent:
		var scene = load('res://addons/gmui/ui/%s/%s.tscn' % [vnode.type, vnode.type])
		newRNode = scene.instantiate()
		rnode.add_child(newRNode)
		for command in vnode.commands:
			var methodName = command['methodName']
			var args = command['args']
			rnode.commands.append(Callable(newRNode, methodName).bindv(args))
		for child in vnode.children:
			_add_rnode_by_vnode(newRNode, child, rnode)
	else:
		newRNode = ClassDB.instantiate(vnode.type)
		newRNode.name = vnode.name
		rnode.add_child(newRNode)
#		newRNode.owner = PathUtils.get_owner(rnode)
		for child in vnode.children:
			_add_rnode_by_vnode(newRNode, child)
	bind_model(newRNode, vnode)
			
func _create_rnode_tree(rnode, vnode, vmRoot = null, mode = Node.INTERNAL_MODE_DISABLED):
	vnode.rnode = rnode
	if rnode == Engine.get_main_loop().current_scene:
		vmRoot = rnode
		for command in vnode.commands:
			var methodName = command['methodName']
			var args = command['args']
			rnode.commands.append(Callable(rnode, methodName).bindv(args))
	for child in vnode.children:
		var newRNode = null
		if child.isScene:
			var scene = load(FileUtils.xml_to_scene_path(child.sceneXMLPath))
			newRNode = scene.instantiate()
#			dont_init(newRNode)
			newRNode.name = child.name
			child.rnode = newRNode
			rnode.add_child(newRNode)
			_set_properties_tree(newRNode, child)
		elif child.isBuiltComponent:
			var scene = load('res://addons/gmui/ui/scenes/%s.tscn' % [child.type])
			newRNode = scene.instantiate()
			newRNode.name = child.name
			rnode.add_child(newRNode)
			_create_rnode_tree(newRNode, child, rnode)
			_set_properties_tree(newRNode, child)
			for command in child.commands:
				var methodName = command['methodName']
				var args = command['args']
				vmRoot.commands.append(Callable(newRNode, methodName).bindv(args))
		else:
			newRNode = ClassDB.instantiate(child.type)
			newRNode.name = child.name
			rnode.add_child(newRNode)
#		newRNode.owner = PathUtils.get_owner(rnode)
			_create_rnode_tree(newRNode, child, rnode)
			_set_properties(newRNode,child)
		bind_model(newRNode, child)
#func get_scene_child(rootNode, node = rootNode, map = {}):
#	for child in node.get_children:
#		if child.scene_file_path != '':
#			map['./'.path_join(rootNode.get_path_to(node).lstrip('.'))] = child
#		get_scene_child(rootNode, child, map)
#	return map

#func set_ast_child(ast, rootMap = {}):
#	if !ast.isScene and !ast.isTemplate and !ast.isSlot:
#		if rootMap.has(ast.path):
#			rootMap[ast.path].ast = ast
#	for child in ast.children:
#		set_ast_child(child, rootMap)

#func dont_init(node):
#	if !Engine.is_editor_hint():
#		if node.scene_file_path != '':
#			node.canInit = false
#		for child in node.get_children():
#			dont_init(child)

func _create_rnode_tree_with_root(rnode, vnode, vmRoot = null):
	var newRNode = null
	if vnode.isScene: 
		var scene = load(FileUtils.xml_to_scene_path(vnode.sceneXMLPath))
		newRNode = scene.instantiate()
		_set_properties_tree(newRNode, vnode)
#		dont_init(newRNode)
		vnode.rnode = rnode
		if rnode != null:
			rnode.add_child(newRNode)
	elif vnode.isBuiltComponent:
		var scene = load('res://addons/gmui/ui/scenes/%s.tscn' % [vnode.type])
		newRNode = scene.instantiate()
		if rnode != null:
			rnode.add_child(newRNode)
		for command in vnode.commands:
			var methodName = command['methodName']
			var args = command['args']
			vmRoot.commands.append(Callable(newRNode, methodName).bindv(args))
		for child in vnode.children:
			_create_rnode_tree_with_root(newRNode, child, rnode)
	else:
		newRNode = ClassDB.instantiate(vnode.type)
		newRNode.name = vnode.name
		_set_properties(newRNode, vnode)
		if rnode != null:
			rnode.add_child(newRNode)
		for child in vnode.children:
			_create_rnode_tree_with_root(newRNode, child, null)
	bind_model(newRNode, vnode)
	return newRNode

func _patch_properties(oldVNode, newVNode):
	if oldVNode.properties != newVNode.properties:
		for key in newVNode.properties:
			oldVNode.rnode.set(key, newVNode.properties[key])
#		for key in oldVNode.properties.keys():
#			oldVNode.rnode.set(key, null)
		oldVNode.properties = newVNode.properties.duplicate(true)
#		for key in oldVNode.properties.keys():
#			oldVNode.rnode.set(key, oldVNode.properties[key])

func _updateChildren(rnode, oldVNodes, newVNodes):
	var oldStart = 0
	var oldEnd = oldVNodes.size() - 1
	var newStart = 0
	var newEnd = newVNodes.size() - 1
	var oldStartNode = oldVNodes[oldStart]
	var oldEndNode = oldVNodes[oldEnd]
	var newStartNode = newVNodes[newStart]
	var newEndNode = newVNodes[newEnd]
	var tempEnd = null
	var tempStart = null
	var keyMap = {}
	var dict = _get_dict(oldVNodes)
	while oldStart <= oldEnd and newStart <= newEnd:
		if oldStartNode == null:
			oldStart += 1
			oldStartNode = oldVNodes[oldStart]
		elif oldEndNode == null:
			oldEnd -= 1
			oldEndNode = oldVNodes[oldEnd]
		elif _is_same_node(oldVNodes[oldStart], newVNodes[newStart]):
			run(oldVNodes[oldStart], newVNodes[newStart])
			oldStart += 1
			newStart += 1
			if oldStart < oldVNodes.size():
				oldStartNode = oldVNodes[oldStart]
			if newStart < newVNodes.size():
				newStartNode = newVNodes[newStart]
		elif _is_same_node(oldVNodes[oldEnd], newVNodes[newEnd]):
			run(oldVNodes[oldEnd], newVNodes[newEnd])
			oldEnd -= 1
			newEnd -= 1
			if oldEnd >= 0:
				oldEndNode = oldVNodes[oldEnd]
			if newEnd >= 0:
				newEndNode = newVNodes[newEnd]
		elif _is_same_node(oldVNodes[oldEnd], newVNodes[newStart]):
			run(oldVNodes[oldEnd], newVNodes[newStart])
			rnode.move_child(oldVNodes[oldEnd].rnode, rnode.get_children().find(oldVNodes[oldStart].rnode))
			newStart += 1
			oldEnd -= 1
			if oldEnd >= 0:
				oldEndNode = oldVNodes[oldEnd]
			if newStart < newVNodes.size():
				newStartNode = newVNodes[newStart]
		elif _is_same_node(oldVNodes[oldStart], newVNodes[newEnd]):
			run(oldVNodes[oldStart], newVNodes[newEnd])
			rnode.move_child(oldVNodes[oldStart].rnode, rnode.get_children().find(oldVNodes[oldEnd].rnode))
			oldStart += 1
			newEnd -= 1
			if newEnd >= 0:
				newEndNode = newVNodes[newEnd]
			if oldStart < oldVNodes.size():
				oldStartNode = oldVNodes[oldStart]
		else:
			var index = dict.get(newStartNode.name, null)
			if index != null:
				var tempVNode = oldVNodes[index]
				rnode.move_child(tempVNode.rnode, rnode.get_children().find(oldStartNode.rnode))
				oldVNodes[index] = null
				run(tempVNode, newStartNode)
			else:
				var newRoot = _create_rnode_tree_with_root(null, newStartNode)
				rnode.add_child(newRoot)
#				set_all_owner(PathUtils.get_owner(rnode), newRoot)
				rnode.move_child(newRoot, rnode.get_children().find(oldVNodes[oldStart].rnode))
			newStart += 1
			if newStart < newVNodes.size():
				newStartNode = newVNodes[newStart]
		
	if oldStart <= oldEnd:
		for i in range(oldStart, oldEnd + 1):
			if oldVNodes[i] != null:
				rnode.remove_child(oldVNodes[i].rnode)
	elif newStart <= newEnd:
		if newEnd < newVNodes.size():
			for i in range(newStart, newEnd + 1):
				_add_rnode_by_vnode(rnode, newVNodes[i], null)
		else:
			for i in range(newStart, newEnd + 1):
				_add_rnode_by_vnode(rnode, newVNodes[i], null, Node.INTERNAL_MODE_FRONT)

func _remove_all_child(node):
	for child in node.get_children():
		_remove_all_child(child)
		node.remove_child(child)
		child.free()

func __remove_all_child_vnode(node):
	node.children.clear()

func _add_all_child_vnode(oldVNode, newVNode):
	oldVNode.children = newVNode.children

func _is_same_node(oldNode, newNode):
	return oldNode.name == newNode.name and oldNode.model == newNode.model
	
func _get_dict(children):
	var dict = {}
	for i in children.size():
		dict[children[i].name] = i
	return dict

func _set_properties(rnode, vnode):
	var vProperties = vnode.properties
	if rnode != null:
		for key in vProperties.keys():
			rnode.set(key, vProperties[key])

func _set_properties_tree(rnode, vnode):
	_set_properties(rnode, vnode)
	for i in rnode.get_children().size():
		if i < vnode.children.size():
			_set_properties_tree(rnode.get_children()[i], vnode.children[i])

func bind_model(newRNode, vnode):
	if newRNode is LineEdit:
		LineEditModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is TabBar:
		TabBarModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is TabContainer:
		TabContainerModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is ColorPicker:
		ColorPickerModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is CheckButton:
		CheckButtonModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is CheckBox:
		CheckBoxModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is TextEdit:
		TextEditModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is CodeEdit:
		CodeEditModelStrategy.new(newRNode, vnode).operate()
	elif newRNode is OptionButton:
		OptionButtonModelStrategy.new(newRNode, vnode).operate()
