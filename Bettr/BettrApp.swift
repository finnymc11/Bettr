//
//  BettrApp.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/21/25.
//


import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct BettrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var currentScreen: Screen = .splash
    @State private var isSignedIn: Bool = false
    
    enum Screen {
        case splash, signUp, home
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.ignoresSafeArea()
                if isSignedIn {
                       Home()
                   } else if currentScreen == .signUp {
                       SignUp(currentScreen: $currentScreen).transition(.opacity)
                       
                   } else {
                       SplashView()
                           .onAppear {
                               DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                                   withAnimation(.easeInOut(duration: 1.0)) {
                                       currentScreen = .signUp
                                   }
                               }
                           }.transition(.opacity)
                   }
            }
            .animation(.easeIn(duration: 2.0), value: currentScreen)
        }
    }
}
