//
//  AccountCreation.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/24/25.
//

import Foundation
import SwiftUI

struct AccountCreation: View{
    @EnvironmentObject var auth: fireAuth
    @Binding var currentScreen: BettrApp.Screen
    @State private var errorMessage: String? = nil
    @State private var email: String = ""
    @State private var passWord: String = ""
    var body: some View{
        VStack{
            Text("Let's create an Account")
                
                .foregroundStyle(Color.white).font(.system(size: 35,weight: .thin, design: .default)).padding(.top, 50)
            Spacer()
            TextField(
                "Email",
                text: $email,
                prompt: Text("Email").foregroundStyle(Color.white.opacity(0.7))
            ).borderedTField()
                .padding()
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)

            
            SecureField(
                "Password",
                text: $passWord,
                prompt: Text("Password").foregroundStyle(Color.white.opacity(0.7))
            )
            .borderedTField()
            .padding()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            Button(action: {
                print("Create account butt")
                // 🚫 Basic password validation
                if passWord.count < 8 || !passWord.contains(where: { $0.isNumber }) {
                    errorMessage = "Password must be at least 8 characters and contain a number."
                    return
                }
                auth.createUser(email: email, password: passWord) { success, error in
                    if success {
                        print("account creation successful")
                        withAnimation{
                            currentScreen = .screenTime
                        }
                        
                    } else {
                        errorMessage = error?.localizedDescription ?? "Unknown error occurred."
                    }
                }
            }) {
                Text("Create account")
                    .frame(maxWidth: .infinity)
            }
        
            .uniformButt().padding(.horizontal,30)
            .padding(.bottom, 100)
        }.cStyle1()
    }
}

#Preview{
    AccountCreation(currentScreen: .constant(BettrApp.Screen.accountCreation))
}
