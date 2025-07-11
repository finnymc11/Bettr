//
//  reportModel.swift
//  activityReport
//
//  Created by CJ Balmaceda on 7/11/25.
//

import Foundation
struct ActivityReport{
     var totalDuration: TimeInterval
}
extension TimeInterval{
    
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        return String(format: "%0.2d:%0.2d",hours,minutes)
    }
}
