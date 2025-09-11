import SwiftUI
import SwiftData
import CoreLocation

struct HomeView: View {
	enum Mode { case none, run, sleep }
	@State private var mode: Mode = .none
	@State private var frameIndex: Int = 0 // 0 or 1
	@State private var windPhase: Bool = false
	@State private var isMenuOpen: Bool = false
	@GestureState private var dragTranslation: CGSize = .zero
	@StateObject private var motion = LocationMotionManager()
	@State private var modeStartedAt: Date? = nil
	private let secondTicker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
	private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

	var body: some View {
		ZStack(alignment: .topLeading) {
			// 사이드 메뉴
			SideMenuView(isOpen: $isMenuOpen, selectMode: setMode(_:))
				.frame(width: 240)
				.offset(x: isMenuOpen ? 0 : -260)
				.accessibilityHidden(!isMenuOpen)
				.animation(.easeInOut(duration: 0.28), value: isMenuOpen)

			// DIM 레이어
			if isMenuOpen {
				Color.black.opacity(0.25)
					.ignoresSafeArea()
					.onTapGesture { toggleMenu() }
					.transition(.opacity)
			}

			// 메인 컨텐츠
			mainContent
				.offset(x: isMenuOpen ? 180 : 0)
				.animation(.easeInOut(duration: 0.28), value: isMenuOpen)
				.allowsHitTesting(!isMenuOpen)

			// 메뉴 버튼 (항상 최상단)
			Button(action: toggleMenu) {
				Image(systemName: isMenuOpen ? "xmark" : "line.3.horizontal")
					.font(.title2.weight(.bold))
					.foregroundColor(.primary)
					.padding(10)
					.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
			}
			.padding(.leading, 14)
			.padding(.top, 60) // 기존 14 -> 60 으로 내려서 다이나믹 아일랜드 아래 위치
		}
		.background(lightGreen)
		.ignoresSafeArea()
		.gesture(dragGesture)
		.onReceive(timer) { _ in
			guard mode != .none else { return }
			frameIndex = (frameIndex + 1) % 2
			if mode == .run { windPhase.toggle() }
		}
		.onReceive(secondTicker) { _ in
			// 단순히 뷰 갱신 트리거 용도 (durationLabel 업데이트)
			guard mode != .none else { return }
			_ = modeStartedAt
		}
		.onChange(of: mode) { _, newValue in
			if newValue != .none { frameIndex = 0 }
			windPhase = false
			modeStartedAt = (newValue == .none) ? nil : Date()
		}
		.onAppear {
			motion.requestAuthorization()
			motion.start()
		}
		.onReceive(motion.$isMoving.removeDuplicates()) { moving in
			withAnimation(.easeInOut(duration: 0.2)) {
				mode = moving ? .run : .sleep
			}
		}
	}

	// 메인 컨텐츠 분리
	private var mainContent: some View {
		VStack(spacing: 18) {
			Spacer(minLength: 20)

			// 상태 라벨
			statusLabel

			ZStack {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(Color.white.opacity(0.18))
				Image(currentImageName)
					.resizable()
					.scaledToFit()
					.padding(16)
					.accessibilityLabel("프레임 이미지")
			}
			.frame(width: 260, height: 260)
			.overlay(alignment: .topTrailing) { sleepOverlay }
			.overlay(alignment: .trailing) { runOverlay }
			.shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)

			// 경과 시간 라벨 (캐릭터 아래)
			durationLabel
			Spacer(minLength: 30)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.padding(.horizontal, 28)
		.padding(.top, 10)
		.padding(.bottom, 10)
	}

	private var sleepOverlay: some View {
		Group {
			if mode == .sleep {
				Text("zzZ")
					.font(.system(size: 26, weight: .semibold, design: .rounded))
					.foregroundColor(Color.blue.opacity(0.9))
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(Capsule().fill(Color.white.opacity(0.55)))
					.rotationEffect(.degrees(-12))
					.padding(.top, 10)
					.padding(.trailing, 10)
			}
		}
	}

	private var runOverlay: some View {
		Group {
			if mode == .run {
				WindStreaks(phase: windPhase)
					.padding(.trailing, 6)
			}
		}
	}

	// 상태 라벨 뷰
	private var statusLabel: some View {
		Group {
			switch mode {
			case .run:
				labelView(text: "런닝중", color: .green)
			case .sleep:
				labelView(text: "숙면중", color: .blue)
			case .none:
				EmptyView()
			}
		}
		.id(mode)
		.transition(.opacity.combined(with: .move(edge: .top)))
		.animation(.easeInOut(duration: 0.25), value: mode)
	}

	private func labelView(text: String, color: Color) -> some View {
		Text(text)
			.font(.system(size: 52, weight: .bold, design: .rounded))
			.foregroundStyle(.primary)
			.padding(.vertical, 10)
			.padding(.horizontal, 20)
			.background(
				Capsule().fill(.ultraThinMaterial)
			)
			.overlay(
				Capsule().stroke(color.opacity(0.35), lineWidth: 2)
			)
			.shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
	}

	// 경과 시간 라벨
	private var durationLabel: some View {
		Group {
			if let text = durationText {
				Text(text)
					.font(.system(size: 22, weight: .semibold, design: .rounded))
					.foregroundColor(.primary)
					.transition(.opacity)
			}
		}
	}

	private var durationText: String? {
		guard let start = modeStartedAt, mode != .none else { return nil }
		let elapsed = Date().timeIntervalSince(start)
		switch mode {
		case .sleep:
			return sleepText(for: elapsed)
		case .run:
			return runText(for: elapsed)
		case .none:
			return nil
		}
	}

	private func sleepText(for elapsed: TimeInterval) -> String {
		let minutes = Int(elapsed / 60)
		let hours = minutes / 60
		let mins = minutes % 60
		return "\(hours)시간 \(mins)분째 숙면중"
	}

	private func runText(for elapsed: TimeInterval) -> String {
		let minutes = max(1, Int(elapsed / 60))
		return "\(minutes)분째 런닝중"
	}

	private func toggleMenu() { withAnimation { isMenuOpen.toggle() } }
	private func setMode(_ new: Mode) { withAnimation { mode = new; isMenuOpen = false } }

	// 드래그 제스처 (열기/닫기)
	private var dragGesture: some Gesture {
		DragGesture(minimumDistance: 15)
			.updating($dragTranslation) { value, state, _ in state = value.translation }
			.onEnded { value in
				let dx = value.translation.width
				if !isMenuOpen && dx > 80 { toggleMenu() }
				else if isMenuOpen && dx < -80 { toggleMenu() }
			}
	}

	private var currentImageName: String {
		switch mode {
		case .run:
			return frameIndex == 0 ? "run1" : "run2"
		case .sleep:
			return frameIndex == 0 ? "sleep1" : "sleep2"
		case .none:
			return "run1" // 기본 정지 화면
		}
	}

	private func toggleRun() {
		mode = (mode == .run) ? .none : .run
	}

	private func toggleSleep() {
		mode = (mode == .sleep) ? .none : .sleep
	}

	private var lightGreen: Color {
		// 연두색 느낌의 연한 초록색
		Color(red: 0.9, green: 1.0, blue: 0.85)
	}
}

// MARK: - Decorative Views
private struct WindStreaks: View {
	let phase: Bool

	var body: some View {
		VStack(spacing: 6) {
			Capsule()
				.fill(Color.white.opacity(0.85))
				.frame(width: 56, height: 6)
				.blur(radius: 0.5)

			Capsule()
				.fill(Color.white.opacity(0.6))
				.frame(width: 40, height: 5)

			Capsule()
				.fill(Color.white.opacity(0.45))
				.frame(width: 28, height: 4)
		}
		.rotationEffect(.degrees(-12))
		.offset(x: phase ? 0 : -10)
		.opacity(phase ? 0.9 : 0.35)
		.animation(.easeOut(duration: 0.5), value: phase)
	}
}

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
	}
}

// MARK: - Side Menu View
struct SideMenuView: View {
	@Binding var isOpen: Bool
	let selectMode: (HomeView.Mode) -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			Text("메뉴")
				.font(.title3.bold())
				.padding(.bottom, 4)

			menuButton(icon: "house", title: "정지") { selectMode(.none) }
			menuButton(icon: "figure.run", title: "달리기") { selectMode(.run) }
			menuButton(icon: "bed.double", title: "잠자기") { selectMode(.sleep) }

			Divider().padding(.vertical, 6)

			menuButton(icon: "xmark", title: "닫기") { withAnimation { isOpen = false } }

			Spacer()
		}
		.padding(.top, 70)
		.padding(.horizontal, 20)
		.frame(maxWidth: .infinity, alignment: .leading)
		.frame(maxHeight: .infinity)
		.background(.ultraThinMaterial)
		.overlay(alignment: .topTrailing) {
			Button(action: { withAnimation { isOpen = false } }) {
				Image(systemName: "chevron.left")
					.font(.headline)
					.padding(8)
					.background(Color.primary.opacity(0.08), in: Circle())
			}
			.padding(.top, 40)
			.padding(.trailing, 12)
		}
		.ignoresSafeArea()
	}

	@ViewBuilder
	private func menuButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack(spacing: 14) {
				Image(systemName: icon)
					.frame(width: 26)
				Text(title)
				Spacer(minLength: 0)
			}
			.font(.system(size: 16, weight: .medium))
			.foregroundColor(.primary)
			.padding(.vertical, 8)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}
