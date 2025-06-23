//
//  BettrApp.swift
//  Bettr
//
//  Created by Finbar McCarron on 6/21/25.
//
 // @State private var initLogIn: Bool = true
 //    var body: some Scene {
 //        WindowGroup {
 //            if initLogIn == true{
 //                signUp()
 //            }else{
 //                mainView()
 //            }
            

 //        }
 //    }


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

    enum Screen {
        case splash, auth, home
    }

    var body: some Scene {
        WindowGroup {
            switch currentScreen {
            case .splash:
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            currentScreen = .auth
                        }
                    }
            case .auth:
                SignUp(currentScreen: $currentScreen)
            case .home:
                Home()
            }
        }
    }
}
