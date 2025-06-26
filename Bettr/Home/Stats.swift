//
//  Stats.swift
//  
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI


import DeviceActivity


struct statsView: View{
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


//                    ScreenTimeReportView()

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

//struct ScreenTimeReportView: View {
//    @State private var context = DeviceActivityReport.Context(rawValue: "DailyReport")
//    @State private var filter = DeviceActivityFilter(
//        segment: .daily(during: Calendar.current.dateInterval(of: .day, for: .now)!),
//        users: .all,
//        devices: .init([.iPhone])
//    )
//
//    var body: some View {
//        DeviceActivityReport(context, filter: filter)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}

