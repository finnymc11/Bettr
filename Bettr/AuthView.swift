//
//  AuthView.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/20/25.
//

import SwiftUI

struct AuthView: View {
    @Binding var currentScreen: BettrApp.Screen

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up or Login")
                .font(.title)
            Button("Sign Up") {
                // Handle Sign Up Logic
                currentScreen = .home
            }
            .buttonStyle(.borderedProminent)

            Button("Login") {
                // Handle Login Logic
                currentScreen = .home
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
