//
//  FirebaseAuth.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/24/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth


class fireAuth: ObservableObject{
    @Published var user: FirebaseAuth.User?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init(){
        authStateListener = FirebaseAuth.Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
    }
    
    deinit{
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?)->Void){
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else { return }
            if (authResult?.user) != nil{
                print("Successful Login")
                completion(true,nil)
            }else {
                print("error: \(String(describing: error?.localizedDescription))")
                completion(false,error)
            }
        }
    }
    
    func createUser(email: String, password: String, completion: @escaping (Bool, Error?)->Void){
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else { return }
            if (authResult?.user) != nil{
                print("Successful Login")
                completion(true,nil)
            }else{
                print("creation error: \(String(describing: error?.localizedDescription))")
                completion(false, error)
            }
        }
    }
}
