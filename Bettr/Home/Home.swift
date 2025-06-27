//
//  Home.swift
//
//
//  Created by Finbar McCarron on 6/17/25.
//

import SwiftUI

struct Home: View {
    @State private var selection: Int = 1
    var body: some View {
        TabView(selection: $selection){
            Tab("Stats", systemImage: "hourglass", value: 0){
                statsView()
            }
            Tab("Home", systemImage: "house.fill", value: 1){
                homeView()
            }
            Tab("Leaderboard", systemImage: "person.3.fill", value: 2){
                leaderView()
            }
        }.tint(.white)
    }
}

struct homeView: View {
    @State private var screenTimeMinutes: Int   = 40    // e.g. 1 h 15 m
    let dailyGoalMinutes: Int                   = 120   // e.g. 2 h target
    @State private var currentScreen: BettrApp.Screen = .home
    private var currentTimeString: String { minutesToString(screenTimeMinutes) }
    private var goalTimeString:    String { minutesToString(dailyGoalMinutes)  }
    private var screenTimeProgress: Double {           // 0.0 … 1.0+
        Double(screenTimeMinutes) / Double(dailyGoalMinutes)
    }

    private var progressColor: Color {
        switch screenTimeProgress {
        case ..<0.5:    return .green
        case 0.5..<1.0: return .yellow
        default:        return .red
        }
    }
    
    private func minutesToString(_ mins: Int) -> String {
        let h = mins / 60
        let m = mins % 60
        
        if h > 0 && m == 0 {
            return "\(h)h"           // e.g. 2h
        } else if h > 0 {
            return "\(h)h \(m)m"     // e.g. 1h 15m
        } else {
            return "\(m)m"           // e.g. 45m
        }
    }
    
    private var exceededGoal: Bool {
        screenTimeMinutes > dailyGoalMinutes
    }

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 40, weight: .heavy)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            VStack() {
                Spacer()
                // Main content
                VStack(spacing: 12) {
                    Text("Screen time today")
                        .foregroundColor(.white)
                        .font(.system(size: 25))
                        .padding(.bottom, 10)
                    
                    //Progress bar
                    GeometryReader { geo in
                        ProgressView(value: screenTimeProgress)
                            .progressViewStyle(.linear)
                            .tint(progressColor)
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .leading) {
                                if !exceededGoal {
                                    Text(currentTimeString)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(
                                            x: {
                                                let barWidth = geo.size.width - 40
                                                let rawX     = barWidth * min(screenTimeProgress, 1.0)
                                                let clamped  = min(max(rawX, 0), barWidth)
                                                return clamped - 20
                                            }(),
                                            y: 18)
                                }
                            }

                            //Trailing label
                            .overlay(alignment: .trailing) {
                                Text(exceededGoal ? currentTimeString : goalTimeString)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .offset(y: 18)
                            }


                            .animation(.easeInOut, value: screenTimeProgress)
                    }
                    .frame(height: 40)                               // gives room for bar + labels
                    .padding(.horizontal, 40)


                    
                }

                Spacer()
            }
            .cStyle1()
            .navigationTitle("Bettr.")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView(currentScreen: $currentScreen)) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }
}


//struct homeView: View {
//    @State private var currentScreen: BettrApp.Screen = .home
//    
//    init() {
//        let appearance = UINavigationBarAppearance()
//        
//        appearance.backgroundColor = UIColor.black
//        appearance.titleTextAttributes = [
//            .foregroundColor: UIColor.white,
//            .font: UIFont.systemFont(ofSize: 40, weight: .heavy)
//        ]
//
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//    }
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 0) {
//                Spacer()
//                // Main content
//                VStack {
//                    Text("Screen time today")
//                        .foregroundColor(.white)
//                        .font(.system(size: 20))
//                }
//                Spacer()
//                // Bottom overlay
//            }.cStyle1()
//            .navigationTitle("Bettr.")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: SettingsView(currentScreen: $currentScreen)) {
//                        Image(systemName: "gear")
//                            .font(.system(size: 20))
//                    }
//                }
//            }
//        }
//        
//    }
//}

#Preview {
    Home()
}

