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
    @Published var user: User?
    
    init(){
        FirebaseAuth.Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?)->Void){
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else { return }
            if let user = authResult?.user{
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
            guard let strongSelf = self else { return }
            if let user = authResult?.user{
                print("Successful Login")
                completion(true,nil)
            }else{
                print("creation error: \(String(describing: error?.localizedDescription))")
                completion(false, error)
            }
        }
    }
}
