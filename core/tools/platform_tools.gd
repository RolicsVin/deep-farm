extends Node


func is_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]


func is_android() -> bool:
	return OS.get_name() == "Android"


func is_ios() -> bool:
	return OS.get_name() == "iOS"
