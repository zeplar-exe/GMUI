@tool
extends Node

var id = 0
var vmDict = {}
var isInited = {}
var xmlDict = {}

func set_vm(vm):
	vmDict[id] = vm
	id += 1

func get_id():
	return id
