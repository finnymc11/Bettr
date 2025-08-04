//
//  TotalActivityReport.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/11/25.
//

import DeviceActivity
import SwiftUI
import ManagedSettings
import Charts

extension DeviceActivityReport.Context {
	static let pieChart = Self("Pie Chart")
	static let barView = Self("Progress Bar")
	static let detailedView = Self("Detailed View")
    static let timeGraph = Self("Time Graph")
}

struct progressBarReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .barView
    let content: (Double) -> ProgressBarView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Double {
        let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
            $0 + $1.totalActivityDuration
        })
        let hours = totalActivityDuration / 3600 // convert from seconds to hours
		print("store to userdefault")
        
        //Screen time data stored in user defaults
		await storeScreenTimeData(totalHours: hours, rawData: data)

        return hours
    }
}

struct detailedReport: DeviceActivityReportScene {
	let context: DeviceActivityReport.Context = .detailedView

	let content: (ScreenTimeData) -> HorizontalBarChartView

	func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ScreenTimeData {
		let totalActivityDuration = await data.flatMap {$0.activitySegments}.reduce(0,{
			$0 + $1.totalActivityDuration
		})
		let hours = totalActivityDuration / 3600


		let detailedData = await extractDetailedData(from: data)
		let screenTimeData = ScreenTimeData(
			date: Date(),
			totalHours: hours,
			totalSeconds: hours * 3600,
			appUsage: detailedData.appUsage,
			categoryUsage: detailedData.categoryUsage,
            dailyHistory: []
		)
		return screenTimeData
	}
}

struct TimeGraphReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .timeGraph
    let content: ([DailyScreenTime]) -> TimeGraphView
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> [DailyScreenTime] {
        let suiteName = "group.com.data.bettr"
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let rawData = sharedDefaults.data(forKey: "dailyScreenTime"),
              let decoded = try? JSONDecoder().decode([DailyScreenTime].self, from: rawData)
        else {
            return []
        }
        
        // 🪵 DEBUG: Print all decoded screen time entries
        print("✅ Loaded \(decoded.count) entries from UserDefaults:")
        for entry in decoded {
            let formatted = DateFormatter()
            formatted.dateStyle = .medium
            formatted.timeStyle = .none
            print("📅 \(formatted.string(from: entry.date)): \(entry.totalHours) hours")
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create an array of the last 7 days, including today
        let last7Days = (0..<7).map { offset -> Date in
            return calendar.date(byAdding: .day, value: -offset, to: today)!
        }

        // Fill in screen time or 0.0 if not present for that day
        let result: [DailyScreenTime] = last7Days.map { date in
            if let existing = decoded.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return DailyScreenTime(date: date, totalHours: existing.totalHours)
            } else {
                return DailyScreenTime(date: date, totalHours: 0.0)
            }
        }

        // Return sorted from oldest to newest (left to right on graph)
        return result.sorted { $0.date < $1.date }
    }
}
