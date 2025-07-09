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
    @State private var showSplash = true
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var currentScreen: Screen = .splash
    @StateObject var auth = fireAuth()
    @State private var showScreenTime = true
    
    enum Screen {
        case splash, signUp, home, accountCreation, settings, screenTime, logIn
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                Color.black.ignoresSafeArea()
                if  /*auth.user != nil && currentScreen != .screenTime*/ currentScreen == .home {
                    Home()
                }else{
                    switch currentScreen {
                    case .splash:
                        SplashView(){
                            withAnimation{
                                currentScreen = .signUp
                            }
                            
                        }
//                        .transition(.opacity)
                    case .signUp:
                        SignUp(currentScreen: $currentScreen)
                        //.environmentObject(auth)
//                            .transition(.opacity)
                    case .accountCreation:
                        AccountCreation(currentScreen: $currentScreen)
//                            .transition(.opacity)
                    case .screenTime:
                        ScreenTime(currentScreen: $currentScreen)
//                            .transition(.opacity)
                    case .home:
                        Home()
//                            .transition(.opacity)
                    case .settings:
                        SettingsView(currentScreen: $currentScreen)
                    case .logIn:
                        logInView(currentScreen: $currentScreen)
//                            .transition(.opacity)
                    }
                    
                }
                
            } .animation(.easeIn(duration: 0.5), value: currentScreen)
                .environmentObject(auth)
                .onChange(of: auth.user) {
                    
                    if auth.user == nil  {
                        withAnimation(){
                            currentScreen = .signUp
                        }
                        
                    }
                }
            
        }
    }
}
