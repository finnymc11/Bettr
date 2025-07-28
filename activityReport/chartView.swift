//
//  chartView.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/16/25.
//

import Charts
import DeviceActivity
import SwiftUI

struct HorizontalBarChartView: View {
	// Sample data: label and value
	let data: ScreenTimeData
	let showApps: Bool

	var usageData: [(label: String, value: Double)] {
		let raw = showApps ? data.appUsage : data.categoryUsage
		return raw.sorted { $0.value > $1.value }
			.map { (label: $0.key, value: $0.value) }
	}

	// Max value to normalize bar length
	var maxValue: Double {
		usageData.map { $0.value }.max() ?? 1
	}

	var body: some View {
		ScrollView{
			VStack(alignment: .leading, spacing: 16) {
				ForEach(usageData, id: \.label) { item in
					HStack(alignment: .center) {
						// App label
						Text(item.label)
							.font(.system(size: 14, weight: .medium))
							.frame(width: 120, alignment: .leading)
							.lineLimit(1)

						// Bar
						ZStack(alignment: .leading) {
							RoundedRectangle(cornerRadius: 5)
								.fill(Color.gray.opacity(0.2))
								.frame(height: 12)

							RoundedRectangle(cornerRadius: 5)
								.fill(Color.blue)
								.frame(
									width: CGFloat(item.value / maxValue) * 180,
									height: 12
								)
						}

						// Time label
						Text(String(format: "%.1f h", item.value))
							.font(.system(size: 12))
							.foregroundColor(.secondary)
							.frame(width: 50, alignment: .trailing)
					}
				}
			}
			.padding()
			.background(Color(.systemBackground))
			.cornerRadius(15)
			.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
			.padding()
		}

	}
}
