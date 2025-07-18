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
                //                    .font(.largeTitle)
                    .font(.system(size: 40, weight: .semibold, design: .default))
                    .padding(.horizontal, 10)
                
                Spacer()
            }
            
            Button(action: {
                print("signup butt")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                    withAnimation{
                        
                        currentScreen = .accountCreation
                    }
                }
               
                
            }){
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
            }.uniformButt().padding(.top, 200)
            Button("Already Have an account? Log In"){
                print("log in")
                currentScreen = .logIn
                
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
        }.cStyle1().preferredColorScheme(.dark)
        
    }
}

#Preview {
    SignUp(currentScreen:.constant(BettrApp.Screen.screenTime) )
}
