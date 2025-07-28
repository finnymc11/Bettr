//
//  reportFuncs.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/25/25.
//

import Foundation
import DeviceActivity
import _DeviceActivity_SwiftUI


struct ScreenTimeData: Codable {
	let date: Date
	let totalHours: Double
	let totalSeconds: Double
	let appUsage: [String: Double]
	let categoryUsage: [String: Double]
}


func storeScreenTimeData(totalHours: Double, rawData: DeviceActivityResults<DeviceActivityData>) async {
	let suiteName = "group.com.data.bettr"
	guard UserDefaults(suiteName:suiteName) != nil else{
		print("wrong suite name")
		return
	}
	let detailedData = await extractDetailedData(from: rawData)
	let screenTimeData = ScreenTimeData(
		date: Date(),
		totalHours: totalHours,
		totalSeconds: totalHours * 3600,
		appUsage: detailedData.appUsage,
		categoryUsage: detailedData.categoryUsage
	)

	do {
		let jsonData = try JSONEncoder().encode(screenTimeData)
		let timestamp = Int(Date().timeIntervalSince1970)
		let key = "screentime_\(timestamp)"
		UserDefaults.standard.set(jsonData, forKey: key)
		//				sharedDefaults.set(jsonData, forKey: key)
		print("✅ Screen time data stored in UserDefaults with key: \(key)")

		//				for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("screentime_") {
		//					print("🗂️ Found screen time key: \(key)")
		//					printAllStoredScreenTimeData()
		//				}
		printLatestScreenTimeData()

	} catch {
		print("❌ Failed to encode screen time data: \(error)")
	}
}



func printAllStoredScreenTimeData() {
	let defaults = UserDefaults.standard
	let allKeys = defaults.dictionaryRepresentation().keys
	let screenTimeKeys = allKeys.filter { $0.hasPrefix("screentime_") }

	if screenTimeKeys.isEmpty {
		print("📭 No stored screen time entries found")
		return
	}

	for key in screenTimeKeys.sorted() {
		print("\n📦 --- Data for key: \(key) ---")
		printScreenTimeData(forKey: key)
	}
}
func printScreenTimeData(forKey key: String) {
	guard let data = UserDefaults.standard.data(forKey: key) else {
		print("❌ No data found for key \(key)")
		return
	}

	do {
		let decoded = try JSONDecoder().decode(ScreenTimeData.self, from: data)

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .medium

		print("📅 Date: \(dateFormatter.string(from: decoded.date))")
		print("🕒 Total Hours: \(String(format: "%.2f", decoded.totalHours))")
		print("🕒 Total Seconds: \(String(format: "%.0f", decoded.totalSeconds))")

		print("\n📱 App Usage:")
		for (app, time) in decoded.appUsage.sorted(by: { $0.value > $1.value }) {
			print("• \(app): \(String(format: "%.2f", time)) hrs")
		}

		print("\n📂 Category Usage:")
		for (category, time) in decoded.categoryUsage.sorted(by: { $0.value > $1.value }) {
			print("• \(category): \(String(format: "%.2f", time)) hrs")
		}

	} catch {
		print("❌ Failed to decode ScreenTimeData for \(key): \(error)")
	}
}



func extractDetailedData(from data: DeviceActivityResults<DeviceActivityData>) async -> (appUsage: [String: Double], categoryUsage: [String: Double]) {
	var appUsage: [String: Double] = [:]
	var categoryUsage: [String: Double] = [:]
	for await segment in data.flatMap({ $0.activitySegments }) {
		// Process categories - also need for await here
		for await category in segment.categories {
			let categoryName = category.category.localizedDisplayName ?? "Unknown"
			let categoryTime = category.totalActivityDuration / 3600 // convert to hours
			categoryUsage[categoryName] = (categoryUsage[categoryName] ?? 0) + categoryTime

			// Process individual apps - also need for await here
			for await app in category.applications {
				let appName = app.application.localizedDisplayName ?? app.application.bundleIdentifier ?? "Unknown"
				let appTime = app.totalActivityDuration / 3600 // convert to hours
				appUsage[appName] = (appUsage[appName] ?? 0) + appTime
			}
		}
	}

	return (appUsage: appUsage, categoryUsage: categoryUsage)
}
func printLatestScreenTimeData() {
	let defaults = UserDefaults.standard
	let allKeys = defaults.dictionaryRepresentation().keys
	let screenTimeKeys = allKeys.filter { $0.hasPrefix("screentime_") }

	guard let latestKey = screenTimeKeys.sorted(by: >).first else {
		print("📭 No stored screen time entries found")
		return
	}

	print("\n🗂️ Latest screen time key: \(latestKey)")
	printScreenTimeData(forKey: latestKey)
}
