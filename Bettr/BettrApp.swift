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
    @State private var showSplash = true
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var currentScreen: Screen = .splash
    @StateObject var auth = fireAuth()
    @State private var showScreenTime = true
    
    enum Screen {
        case splash, signUp, home, accountCreation, settings, screenTime
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.ignoresSafeArea()
                if  auth.user != nil && currentScreen != .screenTime {
                    Home()
                }else{
                    switch currentScreen {
                    case .splash:
                        SplashView(){
                            withAnimation{
                                currentScreen = .signUp
                            }
//                            .onAppear {
//                                if auth.user != nil {
//                                    currentScreen = .home
//                                } else {
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
//                                        withAnimation {
//                                            currentScreen = .screenTime
//                                        }
//                                    }
//                                }
                            }
                            .transition(.opacity)
                    case .signUp:
                        SignUp(currentScreen: $currentScreen)
                        //.environmentObject(auth)
                            .transition(.opacity)
                    case .accountCreation:
                        AccountCreation(currentScreen: $currentScreen)
                            .transition(.opacity)
                    case .screenTime:
                        ScreenTime(currentScreen: $currentScreen)
                            .transition(.opacity)
                    case .home:
                        Home()
                            .transition(.opacity)
                    case .settings:
                        SettingsView(currentScreen: $currentScreen)
                            .transition(.opacity)
                    }
                    
                }
                
            } .animation(.easeIn(duration: 0.5), value: currentScreen)
                .environmentObject(auth)
//                .onChange(of: auth.user) {
//                    
////                        currentScreen = .signUp
//                        if auth.user == nil && currentScreen == .splash {
//                            withAnimation(){
//                                currentScreen = .screenTime
//                            }
//                            
//                    }
//                }
            
        }
    }
}
