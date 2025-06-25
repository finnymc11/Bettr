//
//  ScreenTime.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/25/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity

struct ScreenTime: View {
    let center = AuthorizationCenter.shared
    @Binding var currentScreen: BettrApp.Screen
    @State private var authorizationStatus = "Requesting..."
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    Text("Connect Bettr. to Screen Time")
                        .foregroundColor(.white)
                        .font(.system(size: 40))
                    Spacer()
                    Text("Your sensitive data")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
                .cStyle1()
            }
            .cStyle1()
            .onAppear {
                Task{
                    do {
                        try await center.requestAuthorization(for: .individual)
                        authorizationStatus = "Authorization granted ✅"
                        currentScreen = .home
                    } catch {
                        authorizationStatus = "Authorization failed ❌: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}
