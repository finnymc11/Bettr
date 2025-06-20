//
//  BettrAppApp.swift
//  BettrApp
//
//  Created by Finbar McCarron on 6/17/25.
//

import SwiftUI

@main

struct BettrAppApp: App {
    @State private var initLogIn: Bool = true
    var body: some Scene {
        WindowGroup {
            if initLogIn == true{
                signUp()
            }else{
                mainView()
            }
            

        }
    }
}
