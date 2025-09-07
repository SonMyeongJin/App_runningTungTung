import SwiftUI
import SwiftData

struct HomeView: View {
	@State private var isRunning: Bool = false
	@State private var frameIndex: Int = 0 // 0 -> run1, 1 -> run2
	private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

	var body: some View {
		VStack(spacing: 16) {
			Image(currentImageName)
				.resizable()
				.scaledToFit()
				.accessibilityLabel("running frame")

			Button(action: { isRunning.toggle() }) {
				Text(isRunning ? "Stop" : "Run")
					.font(.headline)
					.padding(.horizontal, 24)
					.padding(.vertical, 10)
					.background(isRunning ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
					.cornerRadius(8)
			}
		}
		.padding()
		.onReceive(timer) { _ in
			guard isRunning else { return }
			frameIndex = (frameIndex + 1) % 2
		}
	}

	private var currentImageName: String {
		frameIndex == 0 ? "run1" : "run2"
	}
}

struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		HomeView()
	}
}
