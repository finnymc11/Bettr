//
//  accountCreation.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/24/25.
//

import Foundation
import SwiftUI

struct createUser: View{
    @EnvironmentObject var auth: fireAuth
    @Binding var currentScreen: BettrApp.Screen
    
    @State private var email: String = ""
    @State private var passWord: String = ""
    var body: some View{
        VStack{
            
            Text("Let's Create an Account").foregroundStyle(Color.white).font(.system(size: 30, design: .default)).padding(.top, 50)
            Spacer()
            TextField(
                "Email",
                text: $email,
                prompt: Text("Email").foregroundStyle(Color.white.opacity(0.7))
            ).borderedTField()
                .padding()
            TextField(
                "Password",
                text: $passWord,
                prompt: Text("Password").foregroundStyle(Color.white.opacity(0.7))
            )
            .borderedTField()
            .padding()
            
            Spacer()
            Button(action:{
                print("Create account butt")
                auth.createUser(email: email, password: passWord) { success, error in
                                    if success {
                                        print("Login successful")
                                        
                                    } else {
                                        print("Error: \(error?.localizedDescription ?? "Unknown error")")
                                    }
                                }
            }){
                Text("Create account").frame(maxWidth: .infinity)
            }.uniformButt().padding(.bottom, 100)
            
            
        }.cStyle1()
    }
}


struct borderedTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
            .foregroundStyle(Color.white)
    }
    
}


//

