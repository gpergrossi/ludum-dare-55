extends Node

@export var score := 0

var array : Array[int]
var dict : Dictionary

var data : DataClass

func _ready():
	print("Autoload did the thing it was supposed to. The score is " + str(score))
	array = []
	data = DataClass.new(57192)


func stuff(arg : int):
	if arg == 1:
		pass


func fa(x):
	var a = x
	print(a)
