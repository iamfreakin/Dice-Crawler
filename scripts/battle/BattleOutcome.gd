class_name BattleOutcome
extends RefCounted
## 굴림 결과의 순수 정산값 (적용 전). 미리보기와 실제 적용이 같은 값을 공유한다.
## 확정 = 이 값을 한 번 commit. 미리보기 = 같은 계산을 commit만 안 함.

var damage: int = 0            ## 타겟에게 줄 데미지 (취약 미반영 원값)
var dealt: int = 0             ## 취약·적 방어·남은 HP를 반영한 실제 HP 감소량
var block: int = 0             ## 플레이어 방어
var burn: int = 0             ## 타겟에게 부여할 화상 (유물 보정 포함)
var apply_weak: int = 0        ## 타겟 약화 지속 턴 (0=없음)
var apply_vulnerable: int = 0  ## 타겟 취약 지속 턴 (0=없음)
var token_gain: int = 0        ## 리롤 토큰 획득
var logs: Array[String] = []   ## 로그 라인
