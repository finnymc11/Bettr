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
    var body: some View {
        NavigationStack{
            VStack{
                List{
                    Section(header: Text("Account")){
                        Button("Logout"){
                            
//                            currentScreen = .splash
                            auth.signOut()
//                            print("User: \(auth.user?.email ?? "No User")")
                            print("Current Screen: \(currentScreen)")
                        }.foregroundStyle(Color.black)
                            .navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                    }.toolbar(.hidden, for:.tabBar)
                }
            }
        }
    }
}

#Preview {
    Home()
}
