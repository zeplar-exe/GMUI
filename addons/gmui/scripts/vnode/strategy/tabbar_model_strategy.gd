class_name TabBarModelStrategy extends RefCounted

var rnode
var vnode

func _init(rnode, vnode):
	self.rnode = rnode
	self.vnode = vnode
	
func operate():
	if vnode.model.has('rName'):
		var vm = vnode.vm
		rnode.tab_changed.connect(vm.data._rset.bind(vnode.model['rName']))
		if vnode.model.isCompModel:
			vm.parent.data.setted.connect(
				func(key, value):
					vm.data.rset(key, value)
			)
			rnode.tab_changed.connect(
				func(text):
					vm.parent.data.rset(vnode.model['rName'], text)
			)