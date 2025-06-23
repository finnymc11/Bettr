//
//  Home.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/17/25.


import SwiftUI

struct Home: View {
    @State private var selection: Int = 0
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

#Preview {
    Home()
}
