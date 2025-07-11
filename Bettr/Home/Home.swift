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
        TabView(selection: $selection) {
            LazyView(statsView())
                .tabItem {
                    Label("Stats", systemImage: "hourglass")
                }.tag(0)
            
            LazyView(homeView())
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }.tag(1)
            LazyView(friendView())
                .tabItem {
                    Label("Friends", systemImage: "person.3.fill")
                }.tag(2)
        }
        .tint(.white)
    }
}

struct homeView: View {
    @ObservedObject var screenTime = ScreenTimeModel.shared
    @State private var totalUsage: TimeInterval = 0
//    Task{
////        totalUsage = await screenTime.get
//        todo()
//    }
    
    @State private var screenTimeMinutes = 40
    private let dailyGoalMinutes = 120
    @State private var currentScreen: BettrApp.Screen = .home
    
    private var screenTimeProgress: Double {
        Double(screenTimeMinutes) / Double(dailyGoalMinutes)
    }
    
    private var progressColor: Color {
        switch screenTimeProgress {
        case ..<0.5: return .green
        case 0.5..<1.0: return .yellow
        default: return .red
        }
    }
    
    private var exceededGoal: Bool {
        screenTimeMinutes > dailyGoalMinutes
    }
    
    private var currentTimeString: String {
        minutesToString(screenTimeMinutes)
    }
    
    private var goalTimeString: String {
        minutesToString(dailyGoalMinutes)
    }
    
    private func minutesToString(_ mins: Int) -> String {
        let h = mins / 60, m = mins % 60
        if h > 0 && m == 0 { return "\(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("Screen time today")
                        .foregroundColor(.white)
                        .font(.title2)
                        .padding(.bottom, 10)
                    
                    ProgressBar(progress: screenTimeProgress,
                                currentTime: currentTimeString,
                                goalTime: goalTimeString,
                                exceededGoal: exceededGoal,
                                progressColor: progressColor)
                    .frame(height: 40)
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
                        Image(systemName: "gear").font(.system(size: 20))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: setupNavigationAppearance)
    }
    
    private func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear // Hides the bottom line
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 40, weight: .heavy)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        appearance.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 10)
        
        
    }
}

struct ProgressBar: View {
    let progress: Double
    let currentTime: String
    let goalTime: String
    let exceededGoal: Bool
    let progressColor: Color
    
    var body: some View {
        GeometryReader { geo in
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(progressColor)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    if !exceededGoal {
                        Text(currentTime)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: labelOffset(for: geo.size.width), y: 18)
                    }
                }
                .overlay(alignment: .trailing) {
                    Text(exceededGoal ? currentTime : goalTime)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .offset(y: 18)
                }
        }
    }
    
    private func labelOffset(for width: CGFloat) -> CGFloat {
        let barWidth = width - 40
        let rawX = barWidth * min(progress, 1.0)
        return min(max(rawX, 0), barWidth) - 20
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content { build() }
}




#Preview {
    Home()
}

