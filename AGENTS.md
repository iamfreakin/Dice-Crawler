# AGENTS.md

이 저장소의 에이전트 작업 규칙은 **[CLAUDE.md](CLAUDE.md)** 에 정본으로 정리되어 있다.
Codex를 포함한 모든 에이전트는 `CLAUDE.md` 의 아키텍처·디렉터리 구조·코딩 컨벤션·
협업 규칙을 동일하게 따른다. (역할 분담 없음 — 공용 규칙.)

게임 기획 전체는 [docs/design.md](docs/design.md) 참조.

## 빠른 참조

- 엔진: Godot 4.6 / GDScript (정적 타입 권장)
- 전역 상태: `GameManager` Autoload
- 데이터: `DiceData` / `EnemyData` / `IntentData` / `RelicData` → Resource + `.tres`
- 전투: `BattleManager` 상태머신 `DRAW → PLAYER_TURN → RESOLVE → ENEMY_TURN → REWARD`
- 명명: 스크립트/씬 `PascalCase`, 변수·함수 `snake_case`, 리소스 인스턴스 `snake_case.tres`
- `.tscn`/`.tres` 동시 편집 금지 (머지 충돌). 작업 영역 분리 후 진행.
