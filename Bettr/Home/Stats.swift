//
//  Stats.swift
//
//
//  Created by CJ Balmaceda on 6/20/25.
//
import SwiftUI
import DeviceActivity
import DeviceActivity

struct statsView: View{
    @State private var averageTime: Double = 0.0
    
    private var filter: DeviceActivityFilter{
        let start = Calendar.current.startOfDay(for: Date())
        let now = Date()
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: now)),
            users: .all,
            devices: .init([.iPhone])
        )
    }
    var body: some View{
        let context: DeviceActivityReport.Context = .timeGraph
        let context2: DeviceActivityReport.Context = .detailedView
        
        NavigationStack {
            VStack{
                DeviceActivityReport(context, filter: filter)
                DeviceActivityReport(context2, filter: filter)
                    .cStyle1()
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            HStack {
                                Text("Statistics")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            NavigationLink(destination: InfoView()) {
                                Image(systemName: "info")
                                    .font(.system(size: 20))
                            }
                        }
                    }
            }
        }
    }
}
