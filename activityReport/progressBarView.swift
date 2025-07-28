//
//  progressBarView.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/15/25.
//
import SwiftUI
import DeviceActivity
import ManagedSettings
import Charts
import Foundation
struct ProgressBarView: View {
	let goalTime: Double
	let totalActivity: Double
	//progressTime total/goal
	//exceedingGoal t/f
	//goalTime userInput
	var hours: Int{
		return Int(totalActivity)
	}
	var screenTimeProgress : Double {
//		totalActivity / goalTime
		min(totalActivity / goalTime, 1.0)
	}
	var progressColor: Color {
		switch screenTimeProgress {
		case ..<0.5: return .green
		case 0.5..<0.9: return .yellow
		default: return .red
		}
	}

	@State private var reachingGoal: Bool = false
	private func minutesToString(_ mins: Int) -> String {
		let h = mins / 60, m = mins % 60
		if h > 0 && m == 0 { return "\(h)h" }
		if h > 0 { return "\(h)h \(m)m" }
		return "\(m)m"
	}

	var body: some View {
		ZStack {
			VStack{
				Text("Today's ScreenTime")
				GeometryReader { geo in
					ProgressView(value: screenTimeProgress)
						.progressViewStyle(.linear)
						.tint(progressColor)
						.frame(maxWidth: .infinity)
						.overlay(alignment: .leading) {
							if !reachingGoal {
								Text("\(String(format: "%.1f", totalActivity))h")
									.font(.system(size: 20, weight: .bold))
									.foregroundColor(.white)
									.offset(x: labelOffset(for: geo.size.width), y: 18)
							}
						}
						.overlay(alignment: .trailing) {
							Text("\(reachingGoal ? String(format:"%.1f",totalActivity) : String(format: "%.1f", goalTime))h")
								.font(.system(size: 20))
								.foregroundColor(.white)
								.offset(y: 18)
								.task{
									if screenTimeProgress >= 0.9 {
										reachingGoal=true
									}
								}
						}
				}
				.frame(minHeight: 20)
				.fixedSize(horizontal: false, vertical: true)
			}
		}
	}
	private func labelOffset(for width: CGFloat) -> CGFloat {
		let barWidth = width - 40
		let rawX = barWidth * min(screenTimeProgress, 1.0)
		return min(max(rawX, 0), barWidth) - 20
	}
}
