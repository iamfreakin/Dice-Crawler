class_name RelicFactory
extends RefCounted
## 유물 풀을 res://resources/relics/*.tres 에서 로드한다.
## 폴더에 .tres 를 추가하면 자동으로 풀에 포함된다.

const RELIC_DIR := "res://resources/relics"

## 전체 유물 풀.
static func all() -> Array[RelicData]:
	var result: Array[RelicData] = []
	for res in Content.load_dir(RELIC_DIR):
		var relic := res as RelicData
		if relic != null:
			result.append(relic)
	return result
