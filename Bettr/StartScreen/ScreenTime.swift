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
    var onComplete: (() -> Void)?
    let center = AuthorizationCenter.shared
    @Binding var currentScreen: BettrApp.Screen
    @State private var authorized: Bool = false
    @State private var authorizationStatus = "Requesting..."
    @State private var showAlert = false
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
            }
            .cStyle1()
            .onAppear {
                showAlert = true

            }.alert("Allow Bettr to access your Screen Time data?", isPresented: $showAlert) {
                Button("Allow"){
                    requestAuthorization()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                        showAlert=false
                        onComplete?()
                        withAnimation{
                            currentScreen = .home
//                            showAlert = false
                        }
                    }
                }
                Button("Cancel", role: .cancel){}
            } message: {
                Text("Bettr. needs access to your Screen Time data to function properly.")
            }
        }/*.animation(.easeIn(duration: 0.5), value: currentScreen)*/.preferredColorScheme(.dark)
    }
    func requestAuthorization() {
        print("bruh")
        Task{
            do{
                try await center.requestAuthorization(for: .individual)
                print("Authorized")
            }catch{
                print("Error: \(error)")
            }
        }
    }
}

#Preview {
    ScreenTime(currentScreen: .constant(BettrApp.Screen.screenTime))
}
