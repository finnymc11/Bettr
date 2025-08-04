//
//  Home.swift
//
//
//  Created by Finbar McCarron on 6/17/25.
//
import SwiftUI
import DeviceActivity

struct Home: View {
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
    @State private var currentScreen: BettrApp.Screen = .home
    let context: DeviceActivityReport.Context = .barView
    @StateObject var model = ScreenTimeModel.shared
    @State private var showLoading = true
    @State private var filter: DeviceActivityFilter?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if showLoading || filter == nil {
                        ProgressView().progressViewStyle(.circular).scaleEffect(1.0)
                    } else {
                        DeviceActivityReport(context, filter: filter!)
                    }
                }
                .padding(.horizontal, 40)
            }
            .onAppear {
                let start = Calendar.current.startOfDay(for: Date())
                let now = Date()
                filter = DeviceActivityFilter(
                    segment: .daily(during: DateInterval(start: start, end: now)),
                    users: .all,
                    devices: .init([.iPhone])
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showLoading = false
                }
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
        .preferredColorScheme(.dark)
        .navBarStyle()
    }
}

//#Preview {
//	homeView()
//}
