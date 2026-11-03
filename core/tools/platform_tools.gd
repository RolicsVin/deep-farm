extends Node


func is_computer() -> bool:
	return OS.get_name().to_lower() in ["windows", "macos"]


func is_wndows() -> bool:
	return OS.get_name().to_lower() == "windows"


func is_macos() -> bool:
	return OS.get_name().to_lower() == "ios"


func is_mobile() -> bool:
	return OS.get_name().to_lower() in ["android", "ios"]


func is_android() -> bool:
	return OS.get_name().to_lower() == "android"


func is_ios() -> bool:
	return OS.get_name().to_lower() == "ios"
