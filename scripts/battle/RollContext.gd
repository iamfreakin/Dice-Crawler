class_name RollContext
extends RefCounted
## 이번 턴 굴림의 순서 있는 이벤트 로그. 직전 결과 = 바로 앞 항목.
## replay/리롤은 이 로그를 처음부터 다시 해석한다 (design.md "롤 컨텍스트" 규약).

var entries: Array[RollEntry] = []
var _next_entry_id: int = 0

func clear() -> void:
	entries.clear()
	_next_entry_id = 0

func is_empty() -> bool:
	return entries.is_empty()

func add(entry: RollEntry) -> void:
	if entry.entry_id < 0:
		entry.entry_id = _next_entry_id
		_next_entry_id += 1
	entries.append(entry)

func has_index(index: int) -> bool:
	return get_entry(index) != null

func get_entry(index: int) -> RollEntry:
	for e in entries:
		if e.index == index:
			return e
	return null
