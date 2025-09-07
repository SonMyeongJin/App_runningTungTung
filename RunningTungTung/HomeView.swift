import SwiftUI
import SwiftData

struct HomeView: View {
	private enum Mode { case none, run, sleep }
	@State private var mode: Mode = .none
	@State private var frameIndex: Int = 0 // 0 or 1
	private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

	var body: some View {
		VStack(spacing: 16) {
			ZStack {
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(Color.white.opacity(0.2))
				Image(currentImageName)
					.resizable()
					.scaledToFit()
					.padding(16)
					.accessibilityLabel("프레임 이미지")
			}
			.frame(width: 260, height: 260)
			.overlay(alignment: .topTrailing) {
				if mode == .sleep {
					Text("zzZ")
						.font(.system(size: 28, weight: .semibold, design: .rounded))
						.foregroundColor(Color.blue.opacity(0.9))
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(
							Capsule().fill(Color.white.opacity(0.6))
						)
						.rotationEffect(.degrees(-12))
						.padding(.top, 10)
						.padding(.trailing, 10)
				}
			}
			.shadow(color: Color.black.opacity(0.6), radius: 8, x: 0, y: 4)

			HStack(spacing: 12) {
				Button(action: toggleRun) {
					Text(mode == .run ? "정지" : "달리기")
						.font(.headline)
						.padding(.horizontal, 24)
						.padding(.vertical, 10)
						.background((mode == .run ? Color.red : Color.green).opacity(0.2))
						.cornerRadius(8)
				}

				Button(action: toggleSleep) {
					Text(mode == .sleep ? "정지" : "잠자기")
						.font(.headline)
						.padding(.horizontal, 24)
						.padding(.vertical, 10)
						.background((mode == .sleep ? Color.red : Color.blue).opacity(0.2))
						.cornerRadius(8)
				}
			}
		}
	.padding()
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(lightGreen)
	.ignoresSafeArea()
		.onReceive(timer) { _ in
			guard mode != .none else { return }
			frameIndex = (frameIndex + 1) % 2
		}
		.onChange(of: mode) { _, newValue in
			if newValue != .none { frameIndex = 0 }
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

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
	}
}
