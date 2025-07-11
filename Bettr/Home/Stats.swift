//
//  Stats.swift
//  
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI
import DeviceActivity



extension DeviceActivityReport.Context{
    static let totalActivity = Self("Total Activity")
}
struct statsView: View{
    @State private var context: DeviceActivityReport.Context = .totalActivity
    private var filter : DeviceActivityFilter{
        let start = Calendar.current.startOfDay(for: Date())
        let now = Date()
        return DeviceActivityFilter(
            segment: .daily(during: DateInterval(start: start, end: now)),
            users: .all,
            devices: .init([.iPhone])
        )
    }
    
    var body: some View{
        NavigationStack {
            VStack(spacing: 0) {
                VStack{
                    Text("🧠")
                        .font(.system(size: 96))
                        .padding(.bottom, -15)
                    Text("Behavioral Analysis")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                        .padding(.bottom, 400)
                    DeviceActivityReport(
                        .totalActivity)
                }.cStyle1()
            }.cStyle1()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Stats")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: InfoView()) {
                        Image(systemName: "info")
                            .font(.system(size: 20))
                            //.foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    statsView()
}

