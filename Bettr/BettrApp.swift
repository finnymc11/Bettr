//
//  BettrApp.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/21/25.
//

import SwiftUI
import FirebaseCore
import UIKit
import Firebase
import FirebaseFirestore

class SearchBarFocusDelegate: NSObject, UISearchBarDelegate {
    var onFocus: () -> Void

    init(onFocus: @escaping () -> Void) {
        self.onFocus = onFocus
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        onFocus()
    }
}

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
    @StateObject var auth = fireAuth()
    @State private var startUp = false
    @State private var currentScreen: Screen = .splash

    enum Screen {
        case splash, signUp, home, accountCreation, settings, screenTime, logIn
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !startUp{
                    Color.black
                        .onAppear(){
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                startUp = true
                                if auth.user != nil {
                                    currentScreen = .home
                                }else{
                                    currentScreen = .signUp
                                }
                            }
                        }
                }
                
                switch currentScreen {
                case .splash:
                    SplashView {
                        // After splash, check auth
                        if auth.user != nil {
                            currentScreen = .home
                        } else {
                            currentScreen = .signUp
                        }
                    }
                case .signUp:
                    SignUp(currentScreen: $currentScreen)
                case .logIn:
                    logInView(currentScreen: $currentScreen)
                case .accountCreation:
                    AccountCreation(currentScreen: $currentScreen)
                case .screenTime:
                    ScreenTime(currentScreen: $currentScreen)
                case .home:
                    Home()
                case .settings:
                    SettingsView(currentScreen: $currentScreen)
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(auth)
            .onReceive(auth.$user) { user in
                if user == nil && currentScreen == .home {
                    currentScreen = .signUp
                } else if user != nil && (currentScreen == .signUp || currentScreen == .logIn) {
                    currentScreen = .home
                }
            }
        }
    }
}

//struct BettrApp: App {
//    @State private var showSplash = true
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @State private var currentScreen: Screen = .splash
//    @StateObject var auth = fireAuth()
//    @State private var showScreenTime = true
//    
//    enum Screen {
//        case splash, signUp, home, accountCreation, settings, screenTime, logIn
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ZStack{
//                Color.black.ignoresSafeArea()
//                if  currentScreen == .home {
//                    Home()
//                }else{
//                    switch currentScreen {
//                    case .splash:
//                        SplashView(){
//                            withAnimation{
//                                currentScreen = .signUp
//                            }
//                            
//                        }
//
//                    case .signUp:
//                        SignUp(currentScreen: $currentScreen)
//                        
//                    case .accountCreation:
//                        AccountCreation(currentScreen: $currentScreen)
////                            .transition(.opacity)
//                    case .screenTime:
//                        ScreenTime(currentScreen: $currentScreen)
////                            .transition(.opacity)
//                    case .home:
//                        Home()
////                            .transition(.opacity)
//                    case .settings:
//                        SettingsView(currentScreen: $currentScreen)
//                    case .logIn:
//                        logInView(currentScreen: $currentScreen)
////                            .transition(.opacity)
//                    }
//                    
//                }
//                
//            } .animation(.easeIn(duration: 0.5), value: currentScreen)
//                .environmentObject(auth)
//                .onChange(of: auth.user) {
//                    
//                    if auth.user == nil  {
//                        withAnimation(){
//                            currentScreen = .signUp
//                        }
//                        
//                    }
//                }
//            
//        }
//    }
//}
