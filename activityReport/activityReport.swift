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
        //        TotalActivityReport { totalActivity in
        //            TotalActivityView(totalActivity: totalActivity)
        //        }
        PieChartReport { totalActivity in
            return PieChartView(totalActivity: totalActivity, totalHours: 4.0) // or any custom goal
        }
        
        progressBarReport { totalActivity in
			return ProgressBarView(goalTime: 4.5, totalActivity: totalActivity)
        }
        // Add more reports here...
    }
}
