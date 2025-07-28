//
//  TotalActivityReport.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/11/25.
//

import DeviceActivity
import SwiftUI
import ManagedSettings

extension DeviceActivityReport.Context {
	static let pieChart = Self("Pie Chart")
	static let barView = Self("Progress Bar")
	static let detailedView = Self("Detailed View")
}

struct PieChartReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .pieChart
    let content: (Double) -> PieChartView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Double {
        let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
            $0 + $1.totalActivityDuration
        })
        let hours = totalActivityDuration / 3600 // convert from seconds to hours
        return hours
    }
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
		await storeScreenTimeData(totalHours: hours, rawData: data)
//		await storeScreenTimeData(data: data)

        return hours
    }

//	 func storeScreenTimeData(totalHours: Double, rawData: DeviceActivityResults<DeviceActivityData>) async {
//		let suiteName = "group.com.data.bettr"
//		guard UserDefaults(suiteName:suiteName) != nil else{
//			print("wrong suite name")
//			return
//		}
//		let detailedData = await extractDetailedData(from: rawData)
//			let screenTimeData = ScreenTimeData(
//				date: Date(),
//				totalHours: totalHours,
//				totalSeconds: totalHours * 3600,
//				appUsage: detailedData.appUsage,
//				categoryUsage: detailedData.categoryUsage
//			)
//
//			do {
//				let jsonData = try JSONEncoder().encode(screenTimeData)
//				let timestamp = Int(Date().timeIntervalSince1970)
//				let key = "screentime_\(timestamp)"
//				UserDefaults.standard.set(jsonData, forKey: key)
////				sharedDefaults.set(jsonData, forKey: key)
//				print("✅ Screen time data stored in UserDefaults with key: \(key)")
//
////				for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("screentime_") {
////					print("🗂️ Found screen time key: \(key)")
////					printAllStoredScreenTimeData()
////				}
//				printLatestScreenTimeData()
//
//			} catch {
//				print("❌ Failed to encode screen time data: \(error)")
//			}
//	}

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
			categoryUsage: detailedData.categoryUsage
		)
		return screenTimeData


	}


}
