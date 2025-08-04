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
    let dailyHistory: [DailyScreenTime]
}

//struct DailyScreenTime: Codable, Identifiable, Equatable {
//    var id: Date { date }
//    let date: Date
//    let totalHours: Double
//}

struct DailyScreenTime: Codable, Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    let totalHours: Double
    var appUsage: [String: Double] = [:]
}

func storeScreenTimeData(totalHours: Double, rawData: DeviceActivityResults<DeviceActivityData>) async {
    let suiteName = "group.com.data.bettr"
    let detailedData = await extractDetailedData(from: rawData)

    guard let sharedDefaults = UserDefaults(suiteName: suiteName) else {
        print("wrong suite name")
        return
    }

    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Load existing dailyHistory if it exists
    var dailyHistory: [DailyScreenTime] = []
    if let raw = sharedDefaults.data(forKey: "dailyScreenTime"),
       let decoded = try? JSONDecoder().decode([DailyScreenTime].self, from: raw) {
        dailyHistory = decoded
    }

    // Load all stored ScreenTimeData entries and convert to DailyScreenTime
    let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
    let screentimeKeys = allKeys.filter { $0.hasPrefix("screentime_") }

    var historicalDict: [Date: DailyScreenTime] = [:]
    
    for key in screentimeKeys {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ScreenTimeData.self, from: data) {
            let day = calendar.startOfDay(for: decoded.date)
            historicalDict[day] = DailyScreenTime(
                date: day,
                totalHours: decoded.totalHours,
                appUsage: decoded.appUsage
            )
        }
    }

    // Merge loaded dailyHistory entries (favor most recent)
    for entry in dailyHistory {
        let day = calendar.startOfDay(for: entry.date)
        historicalDict[day] = entry
    }

    // Add today's new entry (overwrite if exists)
    historicalDict[today] = DailyScreenTime(
        date: today,
        totalHours: totalHours,
        appUsage: detailedData.appUsage
    )

    
    //test
//    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
//        let yestStart = calendar.startOfDay(for: yesterday)
//        historicalDict[yestStart] = DailyScreenTime(
//            date: yestStart,
//            totalHours: 4.0,
//            appUsage: [:] // or inject mock data
//        )
//    }

    // Convert dictionary to array and sort by date ascending
    let fullHistory = historicalDict.values.sorted { $0.date < $1.date }

    // Save full dailyHistory array back to sharedDefaults without filtering
    if let encoded = try? JSONEncoder().encode(fullHistory) {
        sharedDefaults.set(encoded, forKey: "dailyScreenTime")
    }

    // Save today's full ScreenTimeData snapshot including full history
    let screenTimeData = ScreenTimeData(
        date: today,
        totalHours: totalHours,
        totalSeconds: totalHours * 3600,
        appUsage: detailedData.appUsage,
        categoryUsage: detailedData.categoryUsage,
        dailyHistory: fullHistory
    )

    do {
        let jsonData = try JSONEncoder().encode(screenTimeData)
        let key = "screentime_latest"
        UserDefaults.standard.set(jsonData, forKey: key)
        print("✅ Stored full screenTimeData under key: \(key)")
        printLatestScreenTimeData()
    } catch {
        print("❌ Failed to encode screenTimeData: \(error)")
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

		//print("📅 Date: \(dateFormatter.string(from: decoded.date))")
		//print("🕒 Total Hours: \(String(format: "%.2f", decoded.totalHours))")
		//print("🕒 Total Seconds: \(String(format: "%.0f", decoded.totalSeconds))")
        print("📊 History: \(decoded.dailyHistory)")
        print("\n📅 Daily History with App Usage:")
        for day in decoded.dailyHistory {
            print("🗓️ \(day.date): \(String(format: "%.2f", day.totalHours)) hrs")
            for (app, time) in day.appUsage.sorted(by: { $0.value > $1.value }) {
                print("    📱 \(app): \(String(format: "%.2f", time)) hrs")
            }
        }
//		print("\n📱 App Usage:")
//		for (app, time) in decoded.appUsage.sorted(by: { $0.value > $1.value }) {
//			print("• \(app): \(String(format: "%.2f", time)) hrs")
//		}
//
//		print("\n📂 Category Usage:")
//		for (category, time) in decoded.categoryUsage.sorted(by: { $0.value > $1.value }) {
//			print("• \(category): \(String(format: "%.2f", time)) hrs")
//		}

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
