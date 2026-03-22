# 구현 워크플로우: 롤 내전 디스코드 봇 + 웹 시스템

> 생성일: 2026-03-22
> 상태: PLAN ONLY — 실행은 `/sc:sc-implement` 사용

---

## 프로젝트 개요

**프로젝트명:** 롤 내전 봇 (LoL Customs Bot)
**저장 위치:** `/workspaces/workspace/claude/Project/lol-customs-bot/`

**핵심 플로우:**
```
디스코드 /내전 → 인원 모집 (버튼) → 참가자 확정 → 웹 링크 생성
→ 웹사이트에서 팀 구성 (밸런스/순서) → 결과 표시
```

---

## 시스템 아키텍처

```
Discord Bot (discord.js)
    ↕ REST + WebSocket
Backend Server (Express.js + Node.js)
    ↕
Database (SQLite or Redis - 임시 세션)
    ↕
Frontend (React or Vanilla JS)
    ↕ Riot API
라이엇 API (소환사 정보, 티어)
```

---

## 기술 스택

| 레이어 | 기술 | 이유 |
|--------|------|------|
| Discord Bot | discord.js (Node.js) | 가장 활발한 커뮤니티, 버튼/슬래시 커맨드 지원 |
| Backend | Express.js | 가볍고 빠름, discord.js와 같은 언어(JS) |
| 실시간 동기화 | Socket.io | 디스코드 → 웹 실시간 반영 |
| Database | SQLite (개발) → PostgreSQL (배포) | 세션 데이터 저장 |
| Frontend | React + TailwindCSS | 빠른 UI 구성 |
| Riot API | 공식 API | 소환사 티어, 포지션 데이터 |

---

## 구현 단계

### Phase 1 — 프로젝트 셋업 (기반)

**목표:** 개발 환경 구성 및 기본 구조 생성

```
Task 1-1: 프로젝트 폴더 구조 생성
  /lol-customs-bot
    /bot          ← 디스코드 봇
    /server       ← 백엔드 API
    /client       ← 프론트엔드
    /shared       ← 공통 타입/유틸
    README.md

Task 1-2: 패키지 초기화
  - bot: discord.js, dotenv
  - server: express, socket.io, better-sqlite3, cors
  - client: react, tailwindcss, socket.io-client

Task 1-3: 환경변수 설정
  - DISCORD_BOT_TOKEN
  - DISCORD_CLIENT_ID
  - RIOT_API_KEY
  - SERVER_URL
  - PORT
```

**체크포인트:** 봇이 디스코드에 로그인되고 ping 응답

---

### Phase 2 — 디스코드 봇 핵심 기능

**목표:** `/내전` 슬래시 커맨드 + 버튼 인터랙션 구현

```
Task 2-1: 슬래시 커맨드 등록
  /내전 → 옵션: 없음 (봇이 UI 제공)

Task 2-2: 내전 생성 임베드 메시지
  [내전 모집 중!]
  주최자: @유저명
  인원: 0/10
  모드: 선택 안 됨

  버튼: [5vs5] [4vs4] [3vs3]
  버튼: [참가하기] [나가기]

Task 2-3: 버튼 인터랙션 핸들러
  - 모드 선택 시 → 임베드 업데이트
  - 참가하기 클릭 시 → 참가자 목록에 추가 + 임베드 갱신
  - 인원 충족 시 → [팀 구성 시작] 버튼 활성화

Task 2-4: 세션 생성 & 웹 링크 발급
  - 인원 확정 시 서버에 세션 POST
  - 고유 URL 생성: https://도메인/session/{UUID}
  - 디스코드에 링크 메시지 전송

Task 2-5: Riot API 연동
  - 참가자 디스코드 닉 → 라이엇 닉 매핑 (첫 등록 시 저장)
  - 소환사 티어, 주 포지션 조회
```

**체크포인트:** 디스코드에서 전체 플로우 동작, 웹 링크 발급

---

### Phase 3 — 백엔드 API

**목표:** 세션 관리 + 실시간 동기화

```
Task 3-1: 세션 데이터 모델
  Session {
    id: UUID
    mode: "5v5" | "4v4" | "3v3"
    status: "recruiting" | "ready" | "done"
    participants: [
      {
        discordId, discordName,
        riotNick, tier, position,
        joinOrder
      }
    ]
    createdAt, expiresAt
  }

Task 3-2: REST API 엔드포인트
  POST /api/session          ← 봇이 세션 생성
  GET  /api/session/:id      ← 웹이 세션 조회
  POST /api/session/:id/join ← 참가자 추가
  POST /api/session/:id/team ← 팀 구성 결과 저장

Task 3-3: Socket.io 실시간 이벤트
  - participant_joined  → 웹 페이지 실시간 갱신
  - session_ready       → 팀 구성 버튼 활성화
  - teams_assigned      → 팀 결과 표시

Task 3-4: 팀 밸런스 로직
  모드 A - 밸런스 모드:
    - 참가자 티어 점수화 (아이언=1 ~ 챌린저=9)
    - 그리디 알고리즘으로 양팀 점수 균등 배분
    - 포지션 중복 최소화

  모드 B - 순서 모드:
    - 참가 순서대로 홀짝 팀 배정
    - 1,3,5,7,9 → 팀A / 2,4,6,8,10 → 팀B
```

**체크포인트:** API 정상 응답, 실시간 이벤트 테스트

---

### Phase 4 — 프론트엔드 웹

**목표:** 팀 구성 결과 웹 UI

```
Task 4-1: 세션 대기 화면
  - 참가자 실시간 목록 (소환사명, 티어 아이콘)
  - 인원 카운터 (7/10)
  - 인원 미충족 시 대기 애니메이션

Task 4-2: 팀 구성 화면 (인원 충족 후)
  버튼: [밸런스 팀 구성] [순서대로 팀 구성]

Task 4-3: 결과 화면
  [팀 A]              [팀 B]
  탑: 소환사명 (골드)  탑: 소환사명 (플래)
  정글: ...           정글: ...
  미드: ...           미드: ...
  원딜: ...           원딜: ...
  서폿: ...           서폿: ...

  버튼: [다시 섞기] [디스코드에 공유]

Task 4-4: 모바일 반응형
  - 게이머들이 폰으로도 볼 수 있도록

Task 4-5: 디스코드 공유 기능
  - [디스코드에 공유] 클릭 시
  - 봇을 통해 채널에 팀 구성 결과 임베드 전송
```

**체크포인트:** 전체 플로우 E2E 테스트

---

### Phase 5 — 배포

```
Task 5-1: 환경 분리 (개발/프로덕션)
Task 5-2: 배포 방식 결정
  옵션 A: Railway.app (무료 플랜, 쉬움)
  옵션 B: Render.com (무료 플랜)
  옵션 C: VPS (더 많은 제어권)

Task 5-3: 도메인 연결
Task 5-4: README.md 작성 (한국어)
```

---

## 의존성 맵

```
Phase 1 (셋업)
    ↓
Phase 2 (봇) ←→ Phase 3 (서버)  [병렬 가능, 단 API 스펙 먼저 합의]
                     ↓
               Phase 4 (프론트)
                     ↓
               Phase 5 (배포)
```

---

## 리스크 및 고려사항

| 리스크 | 내용 | 대응 |
|--------|------|------|
| Riot API | 소환사 닉네임 변경 시 매핑 깨짐 | PUUID 기반으로 저장 |
| 디스코드 닉 ↔ 라이엇 닉 매핑 | 자동화 불가, 첫 사용 시 등록 필요 | `/등록 라이엇닉네임` 커맨드로 해결 |
| 세션 만료 | 내전 안 하고 방치 | 30분 후 자동 삭제 |
| 무료 배포 슬립 모드 | Railway/Render 무료플랜 비활성화 | 유료 전환 or keep-alive ping |

---

## MVP 범위 (첫 버전)

**포함:**
- `/내전` 커맨드
- 5v5 인원 모집
- 웹 링크 발급
- 밸런스 / 순서 팀 구성
- 결과 웹 표시

**나중에:**
- 포지션 자동 배정 (Riot API 주 포지션 기반)
- 내전 전적 기록
- 서버별 랭킹

---

## 다음 단계

워크플로우 확인 후 → `/sc:sc-implement` 로 Phase 1부터 실행
