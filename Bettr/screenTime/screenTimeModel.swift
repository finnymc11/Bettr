//
//  screenTimeModel.swift
//  Bettr
//
//  Created by CJ Balmaceda on 7/11/25.
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity


extension DeviceActivityName{
    static let daily = Self("daily")
}

class ScreenTimeModel: ObservableObject {
    static let shared = ScreenTimeModel()
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    private init(){}
    
    var appSelection = FamilyActivitySelection() {
        willSet{
            let applications = newValue.applicationTokens
            let categories = newValue.categoryTokens
            
            print("applications: \(applications)")
            print("categories: \(categories)")
            
            store.shield.applications = applications.isEmpty ? nil : applications
            store.shield.applicationCategories = ShieldSettings
                .ActivityCategoryPolicy
                .specific(
                    categories
                )
            store.shield.webDomainCategories = ShieldSettings
                .ActivityCategoryPolicy
                .specific(
                    categories
                )
        }
    }
    func initActivityMonitor(){
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        
        )
        do{
            try center.startMonitoring(.daily,during: schedule)
        }catch{
            print("failed to init activity monitor: \(error.localizedDescription)")
        }
        
    }
    func stopActivityMonitor(){
        center.stopMonitoring()
    }
    
    
    
}
