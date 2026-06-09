# Dice Crawler — 에이전트 작업 가이드 (정본)

> 이 문서는 **Claude Code와 Codex 공용 규칙**이다. 두 에이전트는 역할 구분 없이
> 아래 컨벤션과 구조 규칙을 동일하게 따른다. (`AGENTS.md`는 이 문서를 가리킨다.)
> 게임 기획 전체는 [docs/design.md](docs/design.md) 참조.

## 프로젝트 한 줄 요약

Godot 4.6 + GDScript로 만드는 **턴제 주사위 로그라이크** (Slay the Spire 구조 + 주사위 빌드업). PC / itch.io 우선 출시.

## 기술 스택 & 핵심 아키텍처

- **엔진/언어**: Godot 4.6, GDScript (정적 타입 권장)
- **렌더링**: GL Compatibility (project.godot 설정 유지)
- **전역 상태**: `GameManager` Autoload 가 런(run) 상태를 전역 관리
  (현재 층, HP, 주사위 풀/덱, 리롤 토큰, 보유 유물)
- **데이터는 Resource로**: `DiceData` / `EnemyData` / `IntentData` / `RelicData`
  를 `Resource` 서브클래스로 정의하고 `.tres` 인스턴스로 콘텐츠를 추가한다.
  (코드 수정 없이 데이터만 추가해 콘텐츠 확장)
- **전투는 상태머신**: `BattleManager` 가 명시적 상태머신으로 동작
  `DRAW → PLAYER_TURN → RESOLVE → ENEMY_TURN → REWARD`

## 디렉터리 구조 (이 규칙을 지켜서 파일 배치)

```
res://
├── project.godot
├── scenes/              # 최상위 씬: Battle, Map, Reward, MainMenu (.tscn)
├── scripts/
│   ├── autoload/        # GameManager.gd 등 Autoload 싱글톤
│   ├── battle/          # BattleManager + 전투 로직
│   ├── map/             # 노드 맵 생성/이동
│   └── data/            # Resource 클래스 정의 (DiceData.gd 등)
├── resources/
│   ├── dice/            # 주사위 .tres
│   ├── enemies/         # 적 .tres
│   ├── intents/         # 의도 .tres
│   └── relics/          # 유물 .tres
├── assets/              # sprites / audio / fonts
├── ui/                  # 재사용 UI 씬·스크립트
└── docs/                # design.md 등 기획 문서
```

- 스크립트는 `scripts/` 아래 도메인 폴더에, 데이터 인스턴스(.tres)는 `resources/` 아래에 둔다.
- 씬(.tscn)에 붙는 스크립트는 같은 의미의 `scripts/<도메인>/` 폴더에 둔다.

## 코딩 컨벤션 (두 에이전트 공통 — 반드시 준수)

- **명명**
  - 파일: 스크립트/씬은 `PascalCase` (예: `BattleManager.gd`, `Battle.tscn`),
    리소스 인스턴스는 `snake_case` (예: `goblin_grunt.tres`)
  - 클래스: `class_name PascalCase`
  - 함수·변수: `snake_case`, 상수: `CONSTANT_CASE`
  - private 의도 멤버: 앞에 `_` (예: `_current_state`)
  - 시그널: 과거형 동사 (예: `dice_rolled`, `turn_ended`)
- **타입**: 가능한 한 정적 타입 명시 (`var hp: int`, `func roll() -> int:`)
- **Autoload 접근**: 전역 상태는 `GameManager.xxx` 로 접근. 씬 간 직접 참조 대신 시그널/매니저 경유.
- **enum**으로 상태·속성 표현 (예: `enum State { DRAW, PLAYER_TURN, ... }`,
  `enum Element { FIRE, ICE, LIGHTNING, ... }`)
- **주석/문서**: 한국어 주석 OK. 복잡한 규칙(시너지, 의도 결정)엔 의도를 설명하는 주석을 단다.
- 한 파일에 한 책임. 매니저는 로직, 씬 스크립트는 표현/입력에 집중.

## 작업 규칙 (에이전트 협업)

- **`.tscn`/`.tres` 충돌 주의**: 두 에이전트가 같은 씬 파일을 동시에 편집하면
  Godot 씬은 텍스트 머지가 어렵다. 작업 시작 전 어떤 씬/스크립트를 만질지 분리한다.
- 새 콘텐츠(주사위/적/유물)는 **Resource 클래스 추가가 아니라 `.tres` 추가**로 해결되는지 먼저 확인.
- 새 Autoload·입력맵·프로젝트 설정 변경은 `project.godot` 를 건드리므로 커밋 메시지에 명시.
- 커밋은 의미 단위로. 기능 추가 시 관련 씬+스크립트+리소스를 함께 커밋.

## 현재 상태

- [x] Godot 4.6 프로젝트 초기화 (project.godot, icon)
- [x] 폴더 구조 / 에이전트 문서 / .gitignore(Godot용) 세팅
- [x] GameManager Autoload 골격 (+ project.godot 등록)
- [x] Resource 클래스 정의 (DiceData / FaceData / EnemyData / IntentData)
- [x] BattleManager 상태머신 골격
- [x] 2D 확정 (project.godot 정리, 1280x720)
- [x] 기본 주사위 3종 (StarterDeck 코드 팩토리) + 시작 덱 연결
- [x] 실행 검증용 Main 씬 (F5 → 주사위 굴림 데모)
- [x] 플레이 가능한 1:1 전투 (Battle.tscn = main_scene)
      - EnemyInstance 런타임 HP/방어, EnemyFactory(고블린)
      - RESOLVE: 데미지/방어/속성 시너지 처리
      - ENEMY_TURN: 의도(IntentData) 실행, 의도 공개 표시
      - 리롤 토큰 사용, 승/패 판정
- [x] 전체 게임 루프 (MainMenu → Map → Battle → Reward → Map → Boss)
      - MapGenerator: StS식 분기 노드 맵 (전투/정예/휴식/상점/보스)
      - SceneRouter Autoload: 씬 전환 일원화
      - GameManager: 맵 상태/이동(get_available_nodes/move_to)
      - 노드 유형별 적(고블린/오크정예/드래곤 보스), 보상 3택, 보스 클리어 판정
- [x] 속성 상태이상 시스템 (🔥화상 DoT / ❄️❄️약화 / ⚡⚡취약) + 적 상태 표시
- [x] 유물(RelicData) 시스템 — 보상 선택지 + 전투 훅
      (리롤+1 / 매턴 방어 / 화상 강화 / 최대HP+), 맵에 보유 유물 표시
- [x] 콘텐츠 .tres 이관 — 주사위/적/유물을 res://resources/*.tres 로
      - Content.load_dir/load_one 로더, 팩토리가 .tres 로드 (StarterDeck은 deep duplicate)
      - 콘텐츠 추가 = .tres 파일 추가 (코드 수정 불필요)
- [x] 상점(SHOP) + 골드 — 전투 승리 시 골드 드롭, 상점에서 주사위/유물/회복 구매
- [x] 다중 적 + 타겟 선택 — 적 여러 마리, 클릭으로 공격 대상 지정 (단일 타겟 모델)
      (BATTLE: 고블린+박쥐, ELITE: 오크+고블린, BOSS: 드래곤 단독)
- [ ] 핸드 드로우 N개 중 2개 선택 UI (현재는 핸드 2개 전체 굴림)
- [~] 비주얼 패스 (진행 중) — 화풍 픽셀아트, 에셋 전부 수령(assets/sprites)
      - [x] 코드 전역 테마(UITheme) + 다크 배경
      - [x] 픽셀 에셋 연결 1: 화면 배경, 적/플레이어 스프라이트, 의도 아이콘(32)
      - [x] 픽셀 에셋 연결 2: 주사위 칩(몸체+면 아이콘), 유물 아이콘(보상/상점/맵)
      - [x] UI를 .tscn 노드 구조로 전환(에디터 편집), 좌표 기반 맵+연결선
      - [ ] 폰트(main.ttf) 적용 + 남은 텍스트 다듬기
      - [ ] HP 바, 패널 배경 등 마감
- [ ] 사운드, scenes/Main.tscn(초기 데모) 정리
