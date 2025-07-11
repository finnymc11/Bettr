//
//  activityReport.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/11/25.
//

import DeviceActivity
import SwiftUI



@main
struct activityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
