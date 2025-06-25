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
    //    @State private var isSignedIn: Bool = false
    @StateObject var auth = fireAuth()
    
    enum Screen {
        case splash, signUp, home, createAccount
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.ignoresSafeArea()
                if auth.user != nil {
                    Home()
                } else {
                    switch currentScreen {
                    case .splash:
                        SplashView()
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 9) {
                                    withAnimation {
                                        currentScreen = .signUp
                                    }
                                }
                            }
                            .transition(.opacity)
                        
                    case .signUp:
                        SignUp(currentScreen: $currentScreen)
                            .environmentObject(auth)
                            .transition(.opacity)
                        
                    case .createAccount:
                        createUser(currentScreen: $currentScreen)
                            .environmentObject(auth)
                            .transition(.opacity)
                        
                    case .home:
                        Home()
                    }
                }
            }
            .animation(.easeIn(duration: 0.5), value: currentScreen)
            .environmentObject(auth)
        }
    }
}
