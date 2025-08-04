//
//  Settings.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/24/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var currentScreen: BettrApp.Screen
    @StateObject var model = ScreenTimeModel.shared
    @EnvironmentObject var auth: fireAuth
    @State private var showTab = false
    @State private var showPicker = false
    @State private var goalThreshold: Double = UserDefaults(suiteName: "group.com.data.bettr")?.double(forKey: "goalThreshold") ?? 2.0
    var body: some View {
        NavigationStack{
            VStack{
                if let username = auth.user?.displayName {
                    Text(username)
                        .foregroundColor(.gray)
                }
                List{
                    Section(header: Text("Graph Goal")) {
                        HStack {
                            Text("Daily Goal: \(goalThreshold, specifier: "%.1f") hrs")
                            Spacer()
                        }
                        Slider(value: $goalThreshold, in: 0...6, step: 0.1)
                            .onChange(of: goalThreshold) { newValue in
                                let sharedDefaults = UserDefaults(suiteName: "group.com.data.bettr")
                                sharedDefaults?.set(newValue, forKey: "goalThreshold")
                            }
                    }
                    Section(header: Text("Account")){
                        Button("Log Out"){
                            auth.signOut()
                            print("Current Screen: \(currentScreen)")
                        }.settingsButtStyle()
                        
                        Button("Block Apps"){
                            print("block apps")
                            showPicker.toggle()
                        }.familyActivityPicker(isPresented: $showPicker, selection: $model.appSelection)
                            .settingsButtStyle()
                        Button("Print Saved Apps") {
                            print("Saved Apps: \(model.appSelection.applicationTokens)")
                        }


                           
                    }.listRowBackground(Color.black).listRowSeparator(.hidden)

                }.listStyle(.plain)
                    .cStyle1()
            }
        } .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    Home()
}
