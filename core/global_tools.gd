##Важное замечание: 
##обычно доступ к инструментам осуществляется через ядро, так как это особые,
##специализированные инструменты для работы с экраном или системой.
##GlobalTools - это общие инструменты, поэтому доступ к ним осуществляется
##не через ядро.
extends Node


func move_toward3d(from: Vector3, to: Vector3, delta: float) -> Vector3: ## 3д аналог move_toward
	from.x = move_toward(from.x, to.x, delta)
	from.y = move_toward(from.y, to.y, delta)
	from.z = move_toward(from.z, to.z, delta)
	return from


func move_toward2d(from: Vector2, to: Vector2, delta: float) -> Vector2: ## 2д аналог move_toward
	from.x = move_toward(from.x, to.x, delta)
	from.y = move_toward(from.y, to.y, delta)
	return from
