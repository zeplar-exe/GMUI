class_name LineEditStrategy extends RefCounted

var node = null
var xmlParser = null

func _init(node, xmlParser):
	self.node = node
	self.xmlParser = xmlParser
	
func _operate():
	var nodeType = xmlParser.get_node_name()
	var count = xmlParser.get_attribute_count()
	node.type = nodeType
	for i in count:
		var attrName = xmlParser.get_attribute_name(i)
		var attrValue = xmlParser.get_attribute_value(i)
		if attrName == 'name':
			node.name = attrValue
		elif attrName == 'g-model':
			node.modelDict['text'] = attrValue
		else:
			node.properties[attrName] = str_to_var(attrValue)
