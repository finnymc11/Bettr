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
        progressBarReport { totalScreenTime in
			return ProgressBarView(goalTime: 8, totalActivity: totalScreenTime)
        }
        
		detailedReport { screenTimeData in
			return HorizontalBarChartView(data: screenTimeData, showApps: true)
		}
        
        TimeGraphReport { screenTimeHistory in
            return TimeGraphView(data: screenTimeHistory)
        }
    }
}
