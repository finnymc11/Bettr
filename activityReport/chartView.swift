//
//  chartView.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/16/25.
//

import SwiftUI

import SwiftUI

struct HorizontalBarChartView: View {
	// Sample data: label and value
	let data: [(label: String, value: Double)] = [
		("Apples", 30),
		("Bananas", 60),
		("Cherries", 45),
		("Dates", 80),
		("Elderberries", 20)
	]

	// Max value to normalize bar length
	var maxValue: Double {
		data.map { $0.value }.max() ?? 1
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			ForEach(data, id: \.label) { item in
				HStack {
					Text(item.label)
						.frame(width: 100, alignment: .leading)
					Rectangle()
						.fill(Color.blue)
						.frame(width: CGFloat(item.value / maxValue) * 200, height: 20)
						.cornerRadius(5)
					Text("\(Int(item.value))")
						.padding(.leading, 8)
				}
			}
		}
		.padding()
	}
}

struct HorizontalBarChartView_Previews: PreviewProvider {
	static var previews: some View {
		HorizontalBarChartView()
	}
}
#Preview {
	HorizontalBarChartView()
}
