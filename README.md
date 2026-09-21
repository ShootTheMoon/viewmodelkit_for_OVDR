# viewmodelkit_for_OVDR

OVERDARE 용 1인칭 뷰모델 킷. **ONLY ONE TAP** 에서 쓰던 팔 모델 + 뷰모델 Lua + 블렌더→오버데어 클립 추출 도구를 한 곳에 모았다.

**처음이면 [사용법.md](사용법.md) 부터 읽을 것.**

> OVERDARE 는 Roblox 가 아니다. 비슷해 보이는 API 도 동작이 다를 수 있으니 문서를 보거나 직접 재볼 것.

## 구성

```
blender/
  VMKit_Arms.blend    팔만 남긴 뷰모델 팔 (뼈대 없음, 6조각 강체)
  VMKit_Arms.fbx      위 파일 FBX 내보내기 (오버데어 임포트용)
lua/
  ViewmodelController.lua   뷰모델 본체 (LocalScript)
  ViewmodelConfig.lua       위치·배율·캐릭터별 설정 (ModuleScript)
  ViewmodelAnimData.lua     기본 클립 모음 (ModuleScript)
  FirstPersonLock.lua       1인칭 카메라 고정 (LocalScript)
  clips/ViewmodelAnim*.lua  캐릭터별 애니메이션 클립 (ModuleScript, 50개 = 설정이 부르는 것 전부)
tools/
  build_vmkit.py            armbones FBX -> VMKit_Arms 만드는 스크립트
  make_maxico_*.py          블렌더 액션 -> 클립 Lua 추출 예시
  export_maxico_arms.py     팔 + 무기를 오버데어 임포트용 FBX 로 내보내는 예시
  srcedit.py                .ovdrjm 안 스크립트 Source 를 안전하게 꺼내고 넣는 도우미
  maxico_arms_v1_meta.json  make_maxico_*.py 가 쓰는 파츠 기준 좌표
```

## 팔 모델 (VMKit_Arms)

원본 : `Mixamo_For_OVDR_Arms_armbones.fbx` (Mixamo 기반 OVDR 팔, 뼈 12개).

- 몸통 뼈(Root / LowerTorso / UpperTorso01·02)와 길이 0 인 `*Hand001` 을 버리고 **팔만** 남겼다.
- 스키닝 메시를 뼈마다 잘라 **강체 6조각** 으로 만들었다. 뷰모델 코드는 뼈가 아니라 파츠 CFrame 을 움직인다.
- 파일에 들어있던 T자세 그대로 굽는다. 조각 배정은 면 단위 다수결 (가중치 최대 그룹).
- 재질 `Viewmodel_Suit` (63, 63, 69) 하나. 총 454 삼각형.

| 파츠 | 부모 | 피벗 (m, 블렌더 좌표) |
|---|---|---|
| R_UpperArm | - | (-0.185, 0.029, 1.128) 어깨 |
| R_LowerArm | R_UpperArm | (-0.395, 0.021, 1.127) 팔꿈치 |
| R_Hand | R_LowerArm | (-0.600, 0.013, 1.128) 손목 |
| L_UpperArm | - | ( 0.185, 0.029, 1.128) |
| L_LowerArm | L_UpperArm | ( 0.395, 0.021, 1.127) |
| L_Hand | L_LowerArm | ( 0.600, 0.013, 1.128) |

파츠 이름은 `ViewmodelController` 와 클립이 그대로 쓰는 이름이다. **바꾸지 말 것.**

## 쓰는 법

1. `VMKit_Arms.fbx` (+ 무기) 를 오버데어에 임포트해 Workspace 에 모델로 둔다.
2. `lua/` 스크립트를 넣는다.
   - `ViewmodelController`, `FirstPersonLock` → LocalScript (StarterPlayerScripts)
   - `ViewmodelConfig`, `ViewmodelAnimData`, `clips/*` → ReplicatedStorage 의 ModuleScript (이름 그대로)
3. `ViewmodelConfig.CHARACTERS` 에 캐릭터를 추가한다.
   - `SOURCE` : Workspace 에 둔 뷰모델 모델 이름
   - `PIVOT`  : **레벨에 임포트된 뒤** 잰 양팔 중점. 절대 좌표라 다시 임포트하거나 옮기면 다시 잴 것
   - `OFFSET` : 화면 위치 {X, Y, Z} cm
   - `SHRINK` : 벽·바닥에 붙었을 때 줄어드는 최소 배율
   - `CLIPS`  : 동작 이름 → `ViewmodelAnim<이름>` 모듈
4. 클립은 `tools/make_maxico_*.py` 처럼 블렌더 백그라운드로 뽑는다.
   `blender --background --python make_xxx.py`
   스크립트 안의 파일 경로(BLEND / OUTD)는 자기 환경에 맞게 고칠 것.

## 클립 형식

```lua
return {
    duration = 0.5,      -- 초
    cut = nil,           -- 다음 동작으로 넘어갈 수 있는 시점 (nil = 끝까지)
    posScale = 240,
    parts = { "R_UpperArm", ... },
    frames = { {t, px,py,pz, qw,qx,qy,qz, ...}, ... },  -- 파츠마다 위치3 + 쿼터니언4
}
```

- 각 파츠 값은 대기자세(rest) 대비 변화량 `D = (T(-O)·M(f))·(T(-O)·M(rest))⁻¹`
- 블렌더 → 오버데어 축 변환 `M = ((-1,0,0),(0,0,1),(0,1,0))`, 위치 배율 `posScale`
- `O` 는 뷰모델 피벗(양팔 중심 근처). 기준 프레임 자세가 인게임 대기자세와 같아야 한다 (스크립트가 cm 오차를 찍어준다)

## 주의

- 레벨(.ovdrjm) 안의 스크립트가 원본이다. 여기 `.lua` 는 내보내기 사본이라 고쳐도 레벨에 자동 반영되지 않는다.
- ViewmodelConfig 의 OFFSET / PIVOT 값은 화면을 보며 맞춘 확정값이다. 함부로 되돌리지 말 것.
- MeshPart 는 충돌이 잘 안 먹는다. 뷰모델이 벽을 파고드는 건 컨트롤러의 동적 축소(`_G.VMK`)로 막는다.
