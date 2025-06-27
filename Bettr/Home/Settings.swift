//
//  Settings.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/24/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var currentScreen: BettrApp.Screen
    @EnvironmentObject var auth: fireAuth
    @State private var showTab = false
    var body: some View {
        NavigationStack{
            
            VStack{
                List{
                    Section(header: Text("Account")){
                        Button("Log Out"){
                            auth.signOut()
                            print("Current Screen: \(currentScreen)")
//                            currentScreen = .splash
                        }.foregroundStyle(Color.white).frame(maxWidth: .infinity).padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1)).frame(maxWidth: .infinity)
                           
                    }.listRowBackground(Color.black)/*.toolbar(.hidden, for:.tabBar)*/
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
