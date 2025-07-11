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
    var body: some View {
        NavigationStack{
            VStack{
                if let username = auth.user?.displayName {
                    Text(username)
                        .foregroundColor(.gray)
                }
                List{
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
