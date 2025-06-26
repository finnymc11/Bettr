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
    init() {
        let appearance = UINavigationBarAppearance()
        //appearance.configureWithOpaqueBackground() // makes it solid
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 40, weight: .heavy)
        ]
//        appearance.largeTitleTextAttributes = [
//                .foregroundColor: UIColor.white,
//                .font: UIFont.systemFont(ofSize: 34, weight: .heavy)
//        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()
                // Main content
                VStack {
                    Text("😇")
                        .font(.system(size: 96))
                        .padding(.bottom, -15)
                    Text("10m")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                    Text("Screen time today")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                Spacer()
                // Bottom overlay
                VStack {
                    Text("You're spending about 99% less screen time than the average person")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(.bottom, 10)
                    Text("You are #1 in *insert group name*")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                        .padding(.bottom, 50)
                }
            }.cStyle1()
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

#Preview {
    Home()
}
