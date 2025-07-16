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
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let pieChart = Self("Pie Chart")
    static let barView = Self("Progress Bar")
}

//struct TotalActivityReport: DeviceActivityReportScene {
//    // Define which context your scene will represent.
//    let context: DeviceActivityReport.Context = .totalActivity
//    
//    // Define the custom configuration and the resulting view for this report.
//    let content: (String) -> TotalActivityView
//    
//    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
//        // Reformat the data into a configuration that can be used to create
//        // the report's view.
//        let formatter = DateComponentsFormatter()
//        formatter.allowedUnits = [.day, .hour, .minute, .second]
//        formatter.unitsStyle = .abbreviated
//        formatter.zeroFormattingBehavior = .dropAll
//        
//        let totalActivityDuration = await data.flatMap { $0.activitySegments }.reduce(0, {
//            $0 + $1.totalActivityDuration
//        })
//        
//        let sharedDefaults = UserDefaults(suiteName: "group.com.data.bettr")
//        sharedDefaults?.set(totalActivityDuration, forKey: "totalDuration")
//
//        print("total activity report ext: totalActivityDuration: \(totalActivityDuration)")
//        let storedDuration = sharedDefaults?.double(forKey: "totalDuration") ?? -1
//        
//        print("total activity report ext:  stored totalDuration from UserDefaults: \(storedDuration)")
//        return formatter.string(from: totalActivityDuration) ?? "No activity data"
//    }
//}
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
        return hours
    }
        
}
