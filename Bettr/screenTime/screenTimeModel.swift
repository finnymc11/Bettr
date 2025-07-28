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
import _DeviceActivity_SwiftUI



extension DeviceActivityName{
    static let daily = Self("daily")
}

extension DeviceActivityReport.Context {
	static let detailedView = Self("Detailed View")
	static let pieChart = Self("Pie Chart")
	static let barView = Self("Progress Bar")
}
class ScreenTimeModel: ObservableObject {
    static let shared = ScreenTimeModel()
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let selectionKey = "appSelectionKey"
    private let appGroupDefaults =  UserDefaults(suiteName: "group.com.data.Bettr")
    
    private init(){
        loadSelection()
    }
    
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
            saveSelection()
        }
    }
    
   


	   private func formattedDate() -> String {
		   let formatter = DateFormatter()
		   formatter.dateFormat = "yyyy-MM-dd"
		   return formatter.string(from: Date())
	   }

    func saveSelection(){
        do{
            let data = try JSONEncoder().encode(appSelection)
            UserDefaults.standard.set(data, forKey: selectionKey)

            
            
        }catch{
            print("save selection")
            print("Error saving selection: \(error.localizedDescription)")
        }
    }
    
    func loadSelection(){
        guard let data = UserDefaults.standard.data(forKey: selectionKey) else {return}

        do{
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            DispatchQueue.main.async {
                self.appSelection = selection
            }
        }catch{
            print("load selection selection")
            print("error loading selection: \(error.localizedDescription)")
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
            print("start monitor")
        }catch{
            print("failed to init activity monitor: \(error.localizedDescription)")
        }
        
    }
    func stopActivityMonitor(){
        center.stopMonitoring()
    }
    
    
    
}
