class_name Content
extends RefCounted
## .tres 콘텐츠 로딩 유틸. 폴더에 .tres 를 추가하면 코드 수정 없이 인식된다.

## 폴더 안의 모든 .tres 를 파일명 순으로 로드해 반환.
static func load_dir(dir_path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("Content.load_dir: 폴더를 열 수 없음 — " + dir_path)
		return result
	var files := dir.get_files()
	files.sort()
	for f in files:
		if f.ends_with(".tres") or f.ends_with(".res"):
			var res: Resource = load(dir_path.path_join(f))
			if res != null:
				result.append(res)
			else:
				push_warning("Content.load_dir: 로드 실패 — " + f)
	return result

## 단일 리소스 로드 (실패 시 경고 후 null).
static func load_one(path: String) -> Resource:
	var res: Resource = load(path)
	if res == null:
		push_warning("Content.load_one: 로드 실패 — " + path)
	return res
