-- 뷰모델 조정값 모음.
-- 이 파일 숫자만 고치고 Play 를 다시 누르면 바로 반영된다.
--
-- ※ 주의(AI 포함): 아래 값들은 사용자가 실제 화면을 보며 맞춘 확정값이다.
--   애니메이션을 추가하거나 스크립트를 갱신할 때 임의로 되돌리지 말 것.
return {
	-- 카메라 기준 뷰모델 위치 (cm)
	--   X : 오른쪽(+) / 왼쪽(-)
	--   Y : 위(+)     / 아래(-)
	--   Z : 앞(-)     / 뒤(+)
	OFFSET_X = -10,   -- 확정값. 건드리지 말 것
	OFFSET_Y = -35,
	OFFSET_Z = -55,

	-- 뷰모델 확대 배율
	SCALE = 2.4,

	-- 스폰 후 뷰모델을 숨겨두는 시간(초). 카메라가 자리를 잡을 때까지 기다린다.
	INTRO_DELAY = 1,

		-- 뷰모델 중심으로 삼을 기준점. 임포트된 파츠 좌표 기준이며,
		-- 지금은 Wakizashi_Viewmodel_Split 안의 양팔(Right_Arm_Mesh, Left_Arm_Mesh)의 중점이다.
		-- 이 X 를 키우면 뷰모델이 오른쪽으로, 줄이면 왼쪽으로 간다.
		--
		-- ★ 2026-08-24 재실측. 레벨의 Wakizashi_Viewmodel_Split 에서 직접 뽑았다.
		--   Right_Arm_Mesh (871.558594, 75.402748, 4607.296875)
		--   Left_Arm_Mesh  (832.898987, 70.655594, 4611.125488)
		--   -> 중점        (852.228790, 73.029171, 4609.211182)
		--
		--   옛 값은 792.228790 / 23.029174 / 4679.211182 로, 중점에서 정확히
		--   (-60, -50, +70) 벗어나 있었다. SCALE 2.4 를 타면 화면에서
		--   (144, 120, -168) cm 짜리 이동이 된다 — 뷰모델이 화면 오른쪽으로
		--   쳐박혀 보이던 원인이다. OFFSET_X(-10) 보다 14배 큰 항이라
		--   좌우 위치를 실제로 지배하는 건 OFFSET 이 아니라 여기다.
		--
		--   되돌리려면 아래 세 줄을 792.228790 / 23.029174 / 4679.211182 로.
		--   모델을 다시 임포트하거나 레벨에서 옮기면 여기를 다시 재야 한다.
		PIVOT_X = 852.228790,
		PIVOT_Y = 73.029171,
		PIVOT_Z = 4609.211182,

	-- 연타할 때 이어질 공격 순서.
	-- 이름은 ViewmodelAnimData 안의 항목이거나,
	-- ReplicatedStorage 의 "ViewmodelAnim<이름>" 모듈이면 자동으로 찾는다.
	COMBO = { "Attack1", "Attack2", "Attack3" },

	-- ===== 캐릭터별 뷰모델 =====
	-- 로비 LOADOUT 에서 고른 나라에 따라 다른 뷰모델을 쓴다.
	--   SOURCE : Workspace 에 있는 원본 모델 이름
	--   PIVOT  : 그 모델 안 양팔(Right_Arm_Mesh, Left_Arm_Mesh) CFrame 의 중점
	--   OFFSET : 카메라 기준 화면 위치 { X, Y, Z } cm. 없으면 위 전역 OFFSET_* 을 쓴다
	--   ANIM   : false 면 클립 포즈를 아예 안 먹인다
	--
	-- ★★ PIVOT 은 반드시 "레벨에 임포트된 뒤" 다시 재라. 절대 좌표라서
	--   모델을 다시 임포트하거나 레벨에서 옮기면 그 즉시 무효가 된다.
	--   2026-08-24 에 이걸로 크게 헤맸다 — 와키자시 PIVOT 이 실제 중점에서
	--   (-60, -50, +70) 벗어나 있었고, SCALE 2.4 를 타면 화면에서 144cm 라
	--   뷰모델이 화면 오른쪽으로 쳐박혀 보였다. OFFSET_X(-10) 의 14배 항이라
	--   좌우 위치를 지배하는 건 OFFSET 이 아니라 PIVOT 이다.
	CHARACTERS = {

		-- ★ 2026-09-12 : 마쿠아위틀 (Macuahuitl v03 패키지).
		--   아래 japan1 / japan / korea 는 한 줄도 건드리지 않았다. 완전히 별개 직업이다.
		--   파츠는 9개 — 팔 6 (ODA 기본 아바타 팔을 본별로 자른 것) + 무기 3 (재질별로 묶음).
		--
		-- ★ 임포트 주의 : Studio 의 FBX Import 가 파츠 상대 위치를 보존하지 못했다.
		--   9조각이 제각각 흩어진 채로 들어와서, 블렌더 좌표에서 계산한 값을
		--   9개 CFrame 에 직접 박아넣었다. 다시 임포트하면 또 흩어진다.
		--   매핑 : level = 100 x (-x, z, y) + (1000.944095, -92.593801, 1230.791631)
		--   (평행이동은 두 윗팔로 최소제곱한 뒤 GND_Base 위로 옮긴 값. 잔차 0.000179 cm)
		maxico = {
			-- ★ 2026-09-19 : 새 모델 Maxico_Arms_v1 로 교체 (팔 6 + 마쿠아후이틀 재질별 6 + 금색 판 5).
			--   예전 Macuahuitl_Viewmodel 은 레벨에 없어서 maxico 를 고르면 뷰모델이 안 떴다.
			--   블렌더 mexicoidle_edit.blend 40프레임 자세로 내보냈다.
			SOURCE = "Maxico_Arms_v1",

			-- ★ 2026-09-19 : 새 모델 기준. 양 윗팔 중점이 아니라 japan 과 같은 블렌더 점
			--   O = (0.0274, -0.1984, 1.1279) 를 이 모델 좌표 (level = 100*(-x, z, y) + (930, -40, 1060)) 로 옮긴 값.
			--   같은 카메라 + japan 과 같은 OFFSET 이라 블렌더 FakeFPSCamera 화면이 그대로 나온다.
			--   ★ 앞으로 뽑는 maxico 클립은 이 O 를 원점으로 델타를 뽑아야 한다 (팔 중점 아님).
			--   모델을 레벨에서 옮기면 이 값도 같이 옮겨야 한다.
			PIVOT = { 927.2576, 72.7878, 1040.1578 },

			-- japan1 값에서 출발한다. 화면 보고 맞출 것.
			--   X 오른쪽(+)/왼쪽(-) · Y 위(+)/아래(-) · Z 앞(-)/뒤(+), 단위 cm.
			-- ★ 2026-09-20 사용자 확정값. 화면 보고 맞춘 것이라 되돌리지 말 것.
			OFFSET = { -10, -80, -75 },

			-- ★ 뷰모델 전체를 카메라 중심으로 줄이는 비율 (없으면 1).
			--   뷰모델은 월드에 놓인 진짜 물체라 바닥을 뚫는다. 눈높이는 지면에서 145.8cm
			--   (리그 실측 : 발바닥 -> 머리본 125.8 + FirstPersonLock 카메라 높이 20) 인데,
			--   이 칼은 손잡이 끝이 눈 밑 181cm 까지 내려와 바닥을 35cm 파고들었다.
			--   0.6 이면 눈 밑 109cm -> 바닥 위 37cm 로 뜬다.
			--   원근 때문에 화면에 보이는 크기·위치는 1 일 때와 완전히 같다.
			--   OFFSET · 파츠 크기 · 기준자세 · 애니메이션 이동량에 모두 같이 곱해진다.
			--   japan / korea1 은 일부러 안 건다 (이펙트 크기가 따로 정해져 있어 균형이 깨진다).
			SHRINK = 0.34,
			ANIM = true,

			-- ★ 화면 방향 보정. japan1 과 같은 블렌더 파이프라인(축 매핑 (x,y,z)->(-x,z,y))으로
			--   뽑아서 이미 카메라 앞을 보고 있다. 전역 기본값 180 을 타면 두 번 돌아 뒤를 본다.
			--   뷰모델이 뒤통수로 보이면 이 값을 180 으로 바꾸면 된다.
			YAW = 0,

			-- ★ 이 표에 적힌 것만 재생된다. 여기 없는 이름은 nil 로 돌아가서
			--   와키자시/국궁 클립이 이 팔을 몰고 가지 않는다.
			--   (파츠 이름이 MAC_* 라 다른 나라와 하나도 안 겹치기도 한다)
			CLIPS = {
				-- Macuahuitl V10: 32 clips. Model/part contract remains unchanged from V3.
				-- ★ 2026-09-20 : 새 모델(Maxico_Arms_v1)용 인트로. 블렌더 10~100프레임, 3.0초.
				--   기준자세 = 100프레임 = 임포트된 모델 자세 (실측 차이 0.0018cm) 라 끝나면 대기자세로 그대로 이어진다.
				--   옛 MaxicoIntro 는 MAC_* 파츠용이라 이 모델에선 자세가 안 먹었다.
				Intro = "Maxico1Intro",
				Idle = "MaxicoIdle",
				Holster = "MaxicoHolster",
				Draw = "MaxicoDraw",
				SprintDraw = "MaxicoSprintDraw",
				RareDraw = "MaxicoRareDraw",

				-- ★ 2026-09-20 : 새 모델용 1타. 블렌더 10~60프레임, 1.667초.
				--   cut 1.0333 (블렌더 41프레임) 에서 2타로 넘어간다. 안 누르면 끝까지 돈다.
				--   hitAt 0.70 (31프레임, 칼끝 속도 최고점). 기준자세 = 60프레임 = 임포트된 모델 자세.
				--   Attack2 / Attack3 은 아직 옛 클립이라 자세가 안 먹는다 (타이밍만 돈다).
				-- ★ 2026-09-21 : WalkAttack* / SprintAttack* 를 뺐다.
				--   currentAttackClip() 이 maxico 일 때 속도에 따라 Walk/Sprint 접두사를 붙이는데,
				--   그 이름들이 옛 클립(MAC_* 파츠)을 가리켜서 달리며 공격하면 자세가 안 나왔다.
				--   지금은 이름이 없어 기본 Attack1 / Attack2 로 떨어진다.
				--   뺀 것 : WalkAttack1, WalkAttack2, WalkAttack3, SprintAttack1, SprintAttack2, SprintAttack3
				Attack1 = "Maxico1Attack1",
				-- ★ 2026-09-20 : 새 모델용 2타(마지막 타). 블렌더 10~60프레임, 1.667초.
				--   1타의 41프레임 자세에서 그대로 이어진다 (이음새 실측 0.00cm).
				--   cut 이 없어서 다음 타 예약이 안 걸린다. hitAt 0.50 (25프레임).
				Attack2 = "Maxico1Attack2",
				-- ★ 2026-09-21 : 강공격 = 찌르기 돌진. 블렌더 10~60프레임.
				--   holdAt 1.1초(43프레임)에서 멈춘 채 앞으로 나아가고, 멈추면 거기서 끝까지 간다.
				Thrust = "Maxico1Thrust",
				-- ★ 2026-09-21 : 궁극기(부채꼴 장풍). 블렌더 10~60프레임.
				--   차징은 holdAt(28프레임)에서 멈춰 버티고, 떼면 fireAt(32프레임)부터 끝까지.
				--   장풍은 hitAt(45프레임, 칼이 땅에 닿는 순간)에 터진다.
				Ult = "Maxico1Ult",
				-- Attack3 없음 : 마쿠아후이틀은 2타로 끝난다 (와키자시만 3타).

				-- ★ 2026-09-21 : 새 모델용 막기. 블렌더 10~25프레임(0.5초). 끝 자세에서 멈춰 유지된다.
				BlockIn = "Maxico1BlockIn",
				-- BlockHold 없음 : 없으면 BlockIn 의 마지막 자세를 그대로 유지한다 (옛 클립을 가리키면 자세가 풀린다).
				-- 막기 풀기. 25~40프레임(0.5초), 대기자세로 돌아온다.
				BlockOut = "Maxico1BlockOut",
				CrouchIn = "MaxicoCrouchIn",
				CrouchIdle = "MaxicoCrouchIdle",
				CrouchAttack = "MaxicoCrouchAttack",
				CrouchOut = "MaxicoCrouchOut",

				WalkStart = "MaxicoWalkStart",
				WalkLoop = "MaxicoWalkLoop",
				WalkStop = "MaxicoWalkStop",
				-- ★ 2026-09-21 : 새 모델용 달리기. 블렌더 10~25프레임(0.5초), 대기 -> 달리기.
				RunStart = "Maxico1RunStart",
				-- 25~85프레임(2.0초) 무한 반복. 루프 이음새 2.50cm 남아 있다 (화면 6cm).
				RunLoop = "Maxico1RunLoop",
				-- RunStart 를 거꾸로 재생 (0.5초). 멈출 때 대기자세로 돌아온다.
				RunStop = "Maxico1RunStop",
				SprintTwirl = "MaxicoSprintTwirl",
				KunaiThrow = "MaxicoSprintTwirl",

				JumpSlam = "MaxicoJumpSlam",
				Ryunochi = "MaxicoJumpSlam",
				Transform = "MaxicoTransform",
				UltAttack = "MaxicoUltAttack",
			},
			-- CHARGE_TIME 을 넣지 않는다 -> 공격 버튼이 유지형이 아니라 근접 콤보가 된다.
		},

		-- ★ 2026-09-10 : 새 3분할 팔 뷰모델 (Japan1_Arms).
		--   아래 japan(기존 와키자시)은 한 줄도 건드리지 않았다. 완전히 별개 직업이다.

		-- ★ 2026-09-13 : 와키자시 리메이크 이식 완료.
		--   이 칸의 알맹이는 예전 japan1 그대로다 (Japan1_Arms_v3 + Japan1* 클립).
		--   로비 진열장만 옛 모델(Wakizashi_Viewmodel_Split)로 남겨뒀다 — LobbyUI.DATA.japan 참고.
		--   그래서 보이는 건 옛 칼, 고르면 리메이크가 나온다.
		--   예전 japan 설정은 이랬다 :
		--     SOURCE = "Wakizashi_Viewmodel_Split"
		--     PIVOT = { 852.228790, 73.029171, 4609.211182 }
		--     OFFSET = { -10, -35, -55 } / ANIM = true / CLIPS 없음
		japan = {
			SOURCE = "Japan1_Arms_v3",

			-- ★ 임포트된 뒤 레벨에서 직접 잰 값. 절대좌표라 모델을 옮기면 그 즉시 무효다.
			--   Japan1_Arms_v3 배치 기준 (2026-09-13 재실측. 쿠나이 포함 19파츠)
--   R_UpperArm (655.6750, 60.2743, 1248.7010)
--   L_UpperArm (578.8401, 47.1053, 1251.6146)
--   -> 중점     (617.2576, 53.6898, 1250.1578)
			-- ★ 이 값이 바뀌면 인트로·달리기·공격 클립의 델타 기준도 같이 어긋난다.
			--   클립은 이 피벗을 원점으로 하는 공간에서 뽑혀 있다.
			PIVOT = { 617.2576, 53.6898, 1250.1578 },

			-- ★ 2026-09-11 : 사용자가 화면 보며 맞춘 확정값. 임의로 되돌리지 말 것.
			--   X 오른쪽(+)/왼쪽(-) · Y 위(+)/아래(-) · Z 앞(-)/뒤(+), 단위 cm.
			--   -35 -> -60 -> -70 으로 두 번 내렸다 (뷰모델이 화면 위로 떠 보여서).
			OFFSET = { -10, -70, -75 },
			-- ★ 2026-09-20 : 뷰모델을 카메라 중심으로 줄이는 비율.
			--   이 엔진엔 ViewportFrame / WorldModel / Highlight 가 없어서 (인게임 확인)
			--   뷰모델을 월드와 따로 그릴 방법이 없다. 그래서 눈앞에 바짝 붙이고 작게 만든다.
			--   원근 때문에 화면에 보이는 크기·위치는 1 일 때와 똑같다.
			--   인게임 실측 : 카메라에서 311cm 까지 뻗는다. 눈높이 145.8cm 보다 짧아야
			--   정면 아래를 봐도 바닥을 안 뚫는다 -> 0.40 (124cm)
			SHRINK = 0.34,
			ANIM = true,

			-- ★ 화면 방향 보정. 이 모델은 이미 카메라 앞을 보고 있어서
			--   전역 기본값 180 을 타면 두 번 돌아 뒤를 보게 된다. 0 이 맞다.
			YAW = 0,

			-- ★ 이 표에 적힌 것만 재생된다. 여기 없는 이름은 nil 로 돌아가서
			--   와키자시 클립이 이 팔을 몰고 가지 않는다 (korea 와 같은 수법).
			--   지금은 인트로 하나뿐이다. 공격·막기 클립을 만들면 여기 한 줄씩 추가.
			CLIPS = {
				Intro = "Japan1Intro",

				-- 기본공격 1타. 블렌더 10~73 (30fps).
				--   cut  프레임53 (1.4333초) : 연타하면 여기서 끊고 2타로
				--   full 프레임73 (2.1000초) : 연타 안 하면 여기까지 가서 대기자세 복귀
				-- ★ Attack2 / Attack3 이 이 표에 없으면 연타해도 안 넘어가고
				--   1타가 끝까지 재생된다. 2타를 만들면 여기 한 줄 추가하면 된다.
				Attack1 = "Japan1FirstTap",

				-- 2타. 블렌더 10~73 (30fps).
				--   cut  프레임45 (1.1667초) : 타격 직후. 연타하면 회수 동작을 건너뛰고 3타로
				--   full 프레임73 (2.1000초) : 연타 안 하면 회수까지 돌고 대기자세 복귀
				-- ★ 1타 cut(53) 자세와 2타 첫 프레임이 0.00 cm 로 일치한다 (실측).
				--   그래서 1타에서 2타로 넘어갈 때 손이 안 튄다.
				--   Attack3 이 아직 없어서 2타에서 연타하면 73까지 가고 끝난다.
				Attack2 = "Japan1SecondTap",

				-- 3타 (콤보 마지막). 블렌더 10~80 (30fps).
				--   cut 이 없어서 항상 끝까지 재생되고 대기자세로 복귀한다.
				--   참격(X-blade)은 COMBO 의 "Attack3" 자리에서만 나간다.
				--   2타 cut(45) ↔ 3타 시작(10) 이 0.00 cm 로 일치한다 (실측).
				Attack3 = "Japan1ThirdTap",

				-- ===== 아직 전용 애니가 없는 기술들 =====
				-- ★ 이 표에 이름이 없으면 getClip 이 nil 을 돌려주는데,
				--   궁극기와 비뢰신은 nil 이면 발동 자체를 포기한다
				--   (onUltPressed / onFlyingRaijinPressed 의 `if not getClip(...) then return end`).
				--   그래서 와키자시 클립을 그대로 물려서 로직이 돌게 한다.
				-- ★ 그 클립들의 파츠 이름(Right_Arm_Mesh / Wakizashi_Blade_R …)은
				--   이 모델의 파츠 이름(R_UpperArm / WKZ_R_Blade …)과 하나도 안 겹친다.
				--   그래서 pose[item.PoseName] 이 전부 nil 이 되어 자세는 안 먹고,
				--   피해·이펙트·투사체 같은 로직만 와키자시와 똑같이 돈다.
				--   전용 애니를 만들면 오른쪽 값만 Japan1... 으로 바꾸면 된다.
				Ryunochi = "Japan1Ryunochi",  -- 궁극기 (용). 블렌더 10~115 (30fps)
				-- 비뢰신 (쿠나이 투척 + 순간이동). 블렌더 10~80 (30fps).
				--   throwAt / kunaiHide = 2.1000초 (프레임73) : 쿠나이가 손을 떠난다
				--   holdAt 도 같은 시각 -- 던진 뒤 그 자세로 정지한다
				-- ★ 클립에 쿠나이 파츠가 들어 있다 (Japan1_Arms_v3 에 쿠나이 포함).
				--   28프레임에 왼손에 붙고 73프레임에 손을 떠난다.
				KunaiThrow = "Japan1KunaiThrow",
				-- 막기 : 블렌더 10~20 (30fps). Out 은 In 을 그대로 되감은 것이다.
				BlockIn = "Japan1BlockIn",   -- 막기 시작 (마지막 자세에서 정지)
				BlockOut = "Japan1BlockOut", -- 막기 해제 (평상시 자세로 복귀)
				Draw = "Japan1Draw",        -- 비뢰신 TP 직후 준비모션 (블렌더 10~80, 30fps)

				-- 달리기 : 준비동작 1회 -> 무한반복 -> 멈추면 마무리 1회.
				--   블렌더 10~44 / 45~93 / 94~105 (30fps).
				--   45 와 93 의 자세가 정확히 같아서 반복 이음새가 안 보인다 (실측 0.0000).
				RunStart = "Japan1RunStart",
				RunLoop  = "Japan1RunLoop",
				RunStop  = "Japan1RunStop",
			},
		},

		-- ★ 2026-09-15 : 국궁 리메이크 (korea1). korea 는 한 줄도 안 건드렸다.
		--   모델 Korea1_Arms_v1 = 새 팔 6 + 활 4조각(재질별) + 화살 5조각(재질별).
		--   블렌더 Korea1_Intro.blend 80프레임(idle 기본자세)으로 내보냈다.
		korea1 = {
			-- 2026-09-15 : v1 은 활대(Limb) 메시 안에 시위가 한 벌 더 들어 있어 인게임에서 시위가 두 줄로 보였다.
			--   블렌더에서 중복을 지운 v2 로 교체. 파츠 이름·기준자세는 v1 과 같아서 클립은 그대로 쓴다.
			SOURCE = "Korea1_Arms_v2",
			-- 임포트 후 레벨에서 잰 값 (v2, 좌표 매핑 잔차 0.0001 cm)
			--   R_UpperArm (334.4362, 44.9831, 1253.1736)
			--   L_UpperArm (302.2415, 29.9767, 1229.3655)
			PIVOT = { 318.3389, 37.4799, 1241.2695 },
			-- 같은 팔이라 japan 확정값에서 출발했다. 화면 보고 맞출 것.
			OFFSET = { 10, -70, -75 },
			-- ★ 2026-09-20 : 뷰모델을 카메라 중심으로 줄이는 비율.
			--   이 엔진엔 ViewportFrame / WorldModel / Highlight 가 없어서 (인게임 확인)
			--   뷰모델을 월드와 따로 그릴 방법이 없다. 그래서 눈앞에 바짝 붙이고 작게 만든다.
			--   원근 때문에 화면에 보이는 크기·위치는 1 일 때와 똑같다.
			--   인게임 실측 : 카메라에서 422cm 까지 뻗는다. 눈높이 145.8cm 보다 짧아야
			--   정면 아래를 봐도 바닥을 안 뚫는다 -> 0.35 (148cm)
			SHRINK = 0.29,
			-- japan 과 같은 블렌더 파이프라인·같은 카메라라 0 (실측 : 카메라 차이 0).
			YAW = 0,
			ANIM = true,
			-- korea 와 같은 차징 활. 이게 있어야 컨트롤러가 활 모드로 돈다.
			CHARGE_TIME = 1.2,
			CLIPS = {
				-- 인트로 : 블렌더 10~80 (30fps), 기준 80프레임.
				Intro = "Korea1Intro",
				-- ===== 아직 전용 애니가 없는 동작 : korea 클립을 빌려 로직만 돌린다 =====
				--   파츠 이름이 안 겹쳐서 자세는 안 먹고 발사·차징·궁극기 로직은 그대로 나간다.
				-- 발사+재장전 : Korea1_Fire.blend f70~80 + Korea1_Reload.blend f10~40 (30fps)
				Attack1 = "Korea1Fire",
				-- 당기기 : Korea1_Fire.blend f10~60. 게이지 50% = f45, 100% = f60 (넘으면 정지)
				BowDraw = "Korea1BowDraw",
				-- 달리기 : Korea1_Run.blend (30fps). 준비 1회 -> 무한반복 -> 멈추면 마무리 1회.
				--   준비 f10~23 / 반복 f23~43 (20프레임 주기, f23=f43 실측 0.00) / 마무리 f59~75 (f59=f39)
				RunStart = "Korea1RunStart",
				RunLoop  = "Korea1RunLoop",
				RunStop  = "Korea1RunStop",
				-- 슬라이딩 (주몽의 가호 중 특수공격 버튼) : Korea1_Slide.blend f10~30.
				--   미끄러지는 동안 f18 에서 정지, 끝나면 f24 부터 끝까지 (MELEE.slidePose)
				Slide = "Korea1Slide",
				BowFail = "Korea1Fail",   -- 차징 실패 : Korea1_Fail.blend f10~55
				Ult = "Korea1Ult",   -- 궁극기 f10~75 + 재장전 f10~40 한 클립 (Korea1_Ult / Korea1_Reload)
				BlockIn = "Korea1BlockIn",   -- Korea1_Block.blend f10~20, 끝 자세에서 정지
				BlockOut = "Korea1BlockOut", -- BlockIn 되감기
			},
		},
	},

	-- ===== 파츠 색상 =====
	-- 블렌더 머티리얼 색을 sRGB 로 변환한 값이다.
	-- nil 로 두거나 항목을 지우면 그 파츠는 색을 건드리지 않는다.
	--
	-- 참고: MeshPart 는 파츠당 색을 하나만 가질 수 있다.
	--   팔은 블렌더에서도 단색이라 정확히 같지만,
	--   칼은 블렌더에서 7개 머티리얼(칼날/하몬/츠바/손잡이끈/황동...)로 나뉘어 있어
	--   여기서는 가장 넓은 면적인 칼날색으로 대표시켰다.
	--
	-- ★★ 이 표는 런타임에 part.Color 를 칠하는 경로인데, 이 엔진에서는
	--   그 경로가 화면에 안 나온다 (에러도 안 난다). 실제로 보이는 색은
	--   레벨 파츠의 Color 필드에 박아넣은 값이다. 이 표는 기록용으로 둔다.
		COLORS = {
			-- ===== maxico (Macuahuitl v03) =====
			-- 블렌더 Principled BSDF 의 Base Color 를 sRGB 로 변환한 실측값이다.
			--   팔      Avatar_Graphite_Teal        linear (0.045, 0.105, 0.115)
			--   손잡이  M_Macuahuitl_Material_003   linear (0.0488, 0.3806, 0.0607), metal 0.66
			--   몸통    M_Macuahuitl_Material_002   텍스처 평균 x 0.908 (MULTIPLY 노드)
			--   흑요석  M_Macuahuitl_Material_004   linear 0.0725, metal 0.91
			-- 무기가 3파츠뿐인 건 재질이 3개라서다. MeshPart 는 파츠당 색이 하나다.
			MAC_R_UpperArm      = { 60, 91, 95 },
			MAC_R_LowerArm      = { 60, 91, 95 },
			MAC_R_Hand          = { 60, 91, 95 },
			MAC_L_UpperArm      = { 60, 91, 95 },
			MAC_L_LowerArm      = { 60, 91, 95 },
			MAC_L_Hand          = { 60, 91, 95 },
			MAC_Handle          = { 62, 166, 70 },    -- 기계 손잡이 (녹색 금속)
			MAC_Body            = { 188, 164, 134 },  -- 목재 몸통
			MAC_Obsidian        = { 76, 76, 76 },     -- 흑요석 날

			-- ===== japan (와키자시 리메이크 / Japan1_Arms_v3) =====
			-- 팔은 블렌더에서도 단색(Viewmodel_Suit)이라 값이 정확히 같다.
			-- 칼은 MeshPart 하나에 7개 머티리얼이라 색을 하나만 줄 수 있어
			-- 면적이 가장 넓은 칼날 강철색으로 대표시켰다.
			R_UpperArm          = { 63, 63, 69 },
			R_LowerArm          = { 63, 63, 69 },
			R_Hand              = { 63, 63, 69 },
			L_UpperArm          = { 63, 63, 69 },
			L_LowerArm          = { 63, 63, 69 },
			L_Hand              = { 63, 63, 69 },
			WKZ_R_Blade         = { 182, 182, 182 },
			WKZ_R_Hamon         = { 230, 230, 230 },
			WKZ_R_Guard         = { 36, 36, 38 },
			WKZ_R_Wrap          = { 22, 22, 24 },
			WKZ_R_Brass         = { 180, 132, 55 },
			WKZ_R_RaySkin       = { 210, 210, 200 },
			WKZ_L_Blade         = { 182, 182, 182 },
			WKZ_L_Hamon         = { 230, 230, 230 },
			WKZ_L_Guard         = { 36, 36, 38 },
			WKZ_L_Wrap          = { 22, 22, 24 },
			WKZ_L_Brass         = { 180, 132, 55 },
			WKZ_L_RaySkin       = { 210, 210, 200 },
			Kunai               = { 176, 179, 184 },

			Right_Arm_Mesh      = { 63, 63, 69 },     -- 검은 슈트 (블렌더 Viewmodel_Suit)
			Left_Arm_Mesh       = { 63, 63, 69 },
			Wakizashi_R_Blade   = { 182, 182, 182 },  -- 칼날 강철색
			Wakizashi_L_Blade   = { 182, 182, 182 },
			Wakizashi_R_Hamon   = { 230, 230, 230 },
			Wakizashi_L_Hamon   = { 230, 230, 230 },
			Wakizashi_R_Guard   = { 36, 36, 38 },
			Wakizashi_L_Guard   = { 36, 36, 38 },
			Wakizashi_R_Wrap    = { 22, 22, 24 },
			Wakizashi_L_Wrap    = { 22, 22, 24 },
			Wakizashi_R_Brass   = { 180, 132, 55 },
			Wakizashi_L_Brass   = { 180, 132, 55 },
			Wakizashi_R_RaySkin = { 210, 210, 200 },
			Wakizashi_L_RaySkin = { 210, 210, 200 },

			-- 쿠나이는 임포트할 때 머티리얼이 안 쪼개져서 MeshPart 하나로 들어왔다.
			-- 색을 하나만 줄 수 있어서 면적이 넓은 칼날 강철색으로 대표시켰다.
			-- (검은 손잡이 끈까지 살리려면 블렌더에서 재질별로 분리해 다시 임포트해야 한다)
			Kunai               = { 176, 179, 184 },
			-- 재질별로 쪼개서 다시 임포트하면 손잡이 끈을 따로 검게 줄 수 있다
			Kunai_Steel         = { 176, 179, 184 },  -- 칼날 + 고리
			Kunai_Wrap          = { 20, 20, 23 },     -- 손잡이 끈 (검정)

			-- ===== 국궁 (korea) =====
			-- 합쳐진 MeshPart 라 파츠당 색이 하나다. 넓은 면적 기준으로 대표색을 골랐다.
			Gukgung_Bow         = { 190, 172, 157 },  -- 활 몸통
			Gukgung_String      = { 227, 218, 211 },  -- 시위
			Arrow_Gukgung       = { 120, 96, 62 },    -- 화살 (대나무 대)
			-- ===== korea1 (Korea1_Arms_v1) — 블렌더 재질 색을 sRGB 로 바꾼 값 =====
			Arrow_Gukgung_Nock  = { 247, 246, 241 },
			Arrow_Gukgung_Point = { 221, 192, 124 },
			Arrow_Gukgung_Shaft = { 39, 39, 43 },
			Arrow_Gukgung_Stripe = { 221, 237, 124 },
			Arrow_Gukgung_Vane  = { 89, 124, 206 },
			Gukgung_Grip        = { 87, 74, 57 },
			Gukgung_Limb        = { 190, 172, 157 },
			Gukgung_Tip         = { 194, 126, 132 },
			-- Gukgung_String 은 korea 항목과 값이 같아서 그대로 쓴다.
		},

		-- 색과 함께 적용할 재질. nil 이면 건드리지 않는다.
		-- 금속 느낌을 주려면 "Metal", 무광이면 "Plastic".
		MATERIALS = {
			MAC_R_UpperArm      = "Plastic",
			MAC_R_LowerArm      = "Plastic",
			MAC_R_Hand          = "Plastic",
			MAC_L_UpperArm      = "Plastic",
			MAC_L_LowerArm      = "Plastic",
			MAC_L_Hand          = "Plastic",
			MAC_Handle          = "Metal",
			MAC_Body            = "Plastic",
			MAC_Obsidian        = "Metal",

			R_UpperArm          = "Plastic",
			R_LowerArm          = "Plastic",
			R_Hand              = "Plastic",
			L_UpperArm          = "Plastic",
			L_LowerArm          = "Plastic",
			L_Hand              = "Plastic",
			WKZ_R_Blade         = "Metal",
			WKZ_R_Hamon         = "Metal",
			WKZ_R_Guard         = "Metal",
			WKZ_R_Wrap          = "Plastic",
			WKZ_R_Brass         = "Metal",
			WKZ_R_RaySkin       = "Plastic",
			WKZ_L_Blade         = "Metal",
			WKZ_L_Hamon         = "Metal",
			WKZ_L_Guard         = "Metal",
			WKZ_L_Wrap          = "Plastic",
			WKZ_L_Brass         = "Metal",
			WKZ_L_RaySkin       = "Plastic",
			Kunai               = "Metal",

			Right_Arm_Mesh      = "Plastic",
			Left_Arm_Mesh       = "Plastic",
			Wakizashi_R_Blade   = "Metal",
			Wakizashi_L_Blade   = "Metal",
			Wakizashi_R_Hamon   = "Metal",
			Wakizashi_L_Hamon   = "Metal",
			Wakizashi_R_Guard   = "Metal",
			Wakizashi_L_Guard   = "Metal",
			Wakizashi_R_Wrap    = "Plastic",
			Wakizashi_L_Wrap    = "Plastic",
			Wakizashi_R_Brass   = "Metal",
			Wakizashi_L_Brass   = "Metal",
			Wakizashi_R_RaySkin = "Plastic",
			Wakizashi_L_RaySkin = "Plastic",
			Kunai               = "Metal",
			Kunai_Steel         = "Metal",
			Kunai_Wrap          = "Plastic",

			Gukgung_Bow         = "Plastic",
			Gukgung_String      = "Plastic",
			Arrow_Gukgung       = "Plastic",
			Arrow_Gukgung_Nock  = "Plastic",
			Arrow_Gukgung_Point = "Plastic",
			Arrow_Gukgung_Shaft = "Plastic",
			Arrow_Gukgung_Stripe = "Plastic",
			Arrow_Gukgung_Vane  = "Plastic",
			Gukgung_Grip        = "Plastic",
			Gukgung_Limb        = "Plastic",
			Gukgung_Tip         = "Plastic",
		},
}
