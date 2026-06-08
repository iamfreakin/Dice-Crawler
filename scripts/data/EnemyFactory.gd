class_name EnemyFactory
extends RefCounted
## 적 정의(EnemyData)를 res://resources/enemies/*.tres 에서 로드한다.
## EnemyData 는 전투 중 읽기 전용(런타임 상태는 EnemyInstance 가 보유)이라 공유 인스턴스로 충분.

const GOBLIN_PATH := "res://resources/enemies/goblin.tres"
const ORC_ELITE_PATH := "res://resources/enemies/orc_elite.tres"
const DRAGON_BOSS_PATH := "res://resources/enemies/dragon_boss.tres"

static func goblin() -> EnemyData:
	return Content.load_one(GOBLIN_PATH) as EnemyData

static func orc_elite() -> EnemyData:
	return Content.load_one(ORC_ELITE_PATH) as EnemyData

static func dragon_boss() -> EnemyData:
	return Content.load_one(DRAGON_BOSS_PATH) as EnemyData
