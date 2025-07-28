//
//  screenTimeTest.swift
//  Bettr
//
//  Created by CJ Balmaceda on 7/23/25.
//

import Foundation

struct ScreenTimeData: Codable {
	let date: Date
	let totalHours: Double
	let totalSeconds: Double
	let appUsage: [String: Double]
	let categoryUsage: [String: Double]
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
private func printScreenTimeData(forKey key: String) {
	guard let data = UserDefaults.standard.data(forKey: "screentime_1753297718") else {
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
