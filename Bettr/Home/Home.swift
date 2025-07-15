//
//  Home.swift
//
//
//  Created by Finbar McCarron on 6/17/25.
//

import SwiftUI
import DeviceActivity


struct Home: View {
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
    @State private var selection: Int = 1
    
    var body: some View {
        TabView(selection: $selection) {
            statsView()
                .tabItem {
                    Label("Stats", systemImage: "hourglass")
                }.tag(0)
            
            homeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }.tag(1)

            friendView()

            
            

                .tabItem {
                    Label("Friends", systemImage: "person.3.fill")
                }.tag(2)
        }
        .tint(.white)
    }
}

struct homeView: View {
    @State private var totalUsage: TimeInterval = 0
    
    @State private var currentTime: TimeInterval = 0
    
    private var screenTimeMinutes : Int {
        Int(totalUsage/60)
    }
    private let dailyGoalMinutes = 360
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
//    
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
                                progressColor: progressColor
                    
                    )
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
            DeviceActivityReport(.totalActivity)
                .frame(width: 0, height: 0)
                .hidden()
        }
        .preferredColorScheme(.dark)
        .onAppear{
            setupNavigationAppearance()
        }
        .task{
            print("homeview skibidi")
            let duration = await getScreenTime()
            print("homeview duration \(duration)")
         
            
        }
        
    }
    
    private func getScreenTime() async -> Double {
        let sharedDefaults = UserDefaults(suiteName: "group.com.data.bettr")
        let totalDuration = sharedDefaults?.double(forKey: "totalDuration") ?? 0
        return totalDuration
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
//    @State  var screenTime: Double
    var body: some View {
        ZStack{
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
        }.task{
            print("homeview skibidi")
            let sharedDefaults = UserDefaults(suiteName: "group.com.data.bettr")
            let totalDuration = sharedDefaults?.double(forKey: "totalDuration") ?? 0
            print("totalDuration in home: \(totalDuration)")
//            self.screenTime = totalDuration

        }
      
    }
    
    private func labelOffset(for width: CGFloat) -> CGFloat {
        let barWidth = width - 40
        let rawX = barWidth * min(progress, 1.0)
        return min(max(rawX, 0), barWidth) - 20
    }
}

//struct LazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @autoclosure @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content { build() }
//}
//



#Preview {
    homeView()
}

