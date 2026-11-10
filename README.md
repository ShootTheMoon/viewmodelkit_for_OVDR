# viewmodelkit_for_OVDR

OVERDARE 용 1인칭 뷰모델 킷. **ONLY ONE TAP** 에서 쓰던 팔 모델 + 뷰모델 Lua + 블렌더→오버데어 클립 추출 도구를 한 곳에 모았다.

**처음이면 [사용법.md](사용법.md) 부터 읽을 것.**

> OVERDARE 는 Roblox 가 아니다. 비슷해 보이는 API 도 동작이 다를 수 있으니 문서를 보거나 직접 재볼 것.

## 구성

```
blender/
  VMKit_Arms.blend    팔만 남긴 뷰모델 팔 (뼈대 없음, 6조각 강체)
  VMKit_Arms.fbx      위 파일 FBX 내보내기 (오버데어 임포트용)
  source/
    Mixamo_For_OVDR.fbx               원본 전신 템플릿 (메시 6개, 뼈 22개)
    Mixamo_For_OVDR_Arms.fbx          팔 2개 + 뼈 22개 전부 (바디파츠 업로드용)
    Mixamo_For_OVDR_Arms_armbones.fbx 팔 2개 + 뼈 12개 (build_vmkit.py 입력)
lua/
  ViewmodelController.lua   뷰모델 본체 (LocalScript)
  ViewmodelConfig.lua       위치·배율·캐릭터별 설정 (ModuleScript)
  ViewmodelAnimData.lua     기본 클립 모음 (ModuleScript)
  FirstPersonLock.lua       1인칭 카메라 고정 (LocalScript)
  clips/ViewmodelAnim*.lua  캐릭터별 애니메이션 클립 (ModuleScript, 50개 = 설정이 부르는 것 전부)
tools/
  arms_split.py             원본 전신 FBX -> 팔만 남긴 FBX (Arms / Arms_armbones)
  arms_verify.py            위 결과를 원본과 뼈·포즈·메시 단위로 대조
  arms_render.py            원본(회색)과 결과(빨강)를 겹쳐 정면·측면 직교 렌더 (눈으로 보는 확인)
  build_vmkit.py            armbones FBX -> VMKit_Arms 만드는 스크립트
  capture/                  분리 결과 확인 캡처 (원본 겹치기, 12뼈 버전)
  make_maxico_*.py          블렌더 액션 -> 클립 Lua 추출 예시
  export_maxico_arms.py     팔 + 무기를 오버데어 임포트용 FBX 로 내보내는 예시
  srcedit.py                .ovdrjm 안 스크립트 Source 를 안전하게 꺼내고 넣는 도우미
  maxico_arms_v1_meta.json  make_maxico_*.py 가 쓰는 파츠 기준 좌표
```

## 원본에서 팔 뽑기 (arms_split)

`blender/source/Mixamo_For_OVDR.fbx` 는 OVERDARE 아바타 템플릿 전신이다. 메시는 Head / Torso / LeftArm / RightArm / LeftLeg / RightLeg 6개로 이미 나뉘어 있고, 뼈는 22개(R15 식 UpperArm·LowerArm·Hand), 단위 cm, 애니메이션 없음.

`tools/arms_split.py` 는 팔 메시 2개만 남기고 나머지를 지운다. 트랜스폼·포즈·웨이트는 손대지 않는다.

```
blender -b --python tools/arms_split.py -- blender/source/Mixamo_For_OVDR.fbx OUT_DIR                   # Arms.fbx (뼈 22)
blender -b --python tools/arms_split.py -- blender/source/Mixamo_For_OVDR.fbx OUT_DIR --arm-bones-only  # Arms_armbones.fbx (뼈 12)
blender -b --python tools/arms_verify.py -- blender/source/Mixamo_For_OVDR.fbx OUT_DIR/Mixamo_For_OVDR_Arms.fbx
```

- 두 결과 모두 원본과 라운드트립 대조 완료 : 뼈 위치 오차 0.001 cm 이하, 포즈 본 22개 일치, 팔 메시 verts 127/114·웨이트 그룹 3+3 유지, Armature scale 0.01·cm 단위 유지.
- 파일은 rest 가 A포즈이고 그 위에 T포즈가 얹힌 구조다. 둘 다 보존된다.
- `--arm-bones-only` 는 머리 2개·다리 8개 뼈를 지우고 팔 체인 8개 + 팔이 매달리는 Root → LowerTorso → UpperTorso01 → UpperTorso02 4개를 남긴다. 몸통 연결선까지 지우면 팔 뼈가 부모 없이 떠서 리그에 붙일 때 기준이 어긋난다.
- 바디파츠로 업로드할 땐 Arms_armbones 를 먼저 넣어 보고, Studio 가 거부하면 뼈 22개짜리 Arms 로.
- Blender 는 기본 FBX export 옵션으로 스케일이 그대로 왕복된다. `--scale-mode ALL` 은 그게 깨졌을 때만.

## 팔 모델 (VMKit_Arms)

원본 : `blender/source/Mixamo_For_OVDR_Arms_armbones.fbx` (위 단계의 결과, 뼈 12개).

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
