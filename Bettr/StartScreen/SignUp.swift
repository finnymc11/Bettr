//
//  SignUp.swift
//  BettrApp
//
//  Created by CJ Balmaceda on 6/20/25.
//

import Foundation
import SwiftUI

struct SignUp: View{
    @Binding var currentScreen: BettrApp.Screen
    var body: some View{
        VStack{
            HStack{
                Text("Are you ready to be better?")
                    .foregroundColor(.white)
                    .padding(.trailing)
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    
                Spacer()
            }
           
            Button(action: {
                print("signup butt")
                currentScreen = .home
            }){
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
            }.uniformButt().padding(.top, 200)
            Button("Already Have an account? Log In"){
                print("log in")
                currentScreen = .home
            }.foregroundColor(.white)
        }.cStyle1().padding(.horizontal, 10)
        
    }
}
