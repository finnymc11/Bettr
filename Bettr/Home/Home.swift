//
//  Home.swift
//
//
//  Created by Finbar McCarron on 6/17/25.
//
import SwiftUI
import DeviceActivity


//extension DeviceActivityReport.Context {
//	static let barView = Self("Progress Bar")
//	    static let pieChart = Self("Pie Chart")
//
//}
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
	let context : DeviceActivityReport.Context = .barView
	@StateObject var model = ScreenTimeModel.shared

	private var filter : DeviceActivityFilter{
		let start = Calendar.current.startOfDay(for: Date())
		let now = Date()
		return DeviceActivityFilter(
			segment: .daily(during: DateInterval(start: start, end: now)),
			users: .all,
			devices: .init([.iPhone])
		)
	}

	@State private var showLoading = true
	var body: some View {

		NavigationStack {
			ZStack {
				Spacer()
				DeviceActivityReport(context, filter: filter).hidden()
					VStack{
						if showLoading{
							ProgressView().progressViewStyle(.circular).scaleEffect(1.0)
						}else{
							DeviceActivityReport(context, filter: filter)
						}
					}

				.padding(.horizontal, 40)
				Spacer()
			}.onAppear{

				print("bruh")
				DispatchQueue.main.asyncAfter(deadline: .now()+5){
					showLoading = false
				}
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
		.navBarStyle()

	}

}
//#Preview {
//	homeView()
//}
