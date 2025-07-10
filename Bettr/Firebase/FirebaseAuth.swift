//
//  FirebaseAuth.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/24/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


class fireAuth: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var friendRequests: [SearchResultItem] = []
    @Published var friends: [SearchResultItem] = []

    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var listener: ListenerRegistration?
    
    init() {
        authStateListener = FirebaseAuth.Auth.auth().addStateDidChangeListener { auth, user in
            self.user = user
            self.fetchFriendRequests()
        }
    }
    
    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
            authStateListener = nil
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else { return }
            if (authResult?.user) != nil {
                print("Successful Login")
                completion(true, nil)
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
                completion(false, error)
            }
        }
    }
    
    func createUser(email: String, password: String, username: String, completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard self != nil else { return }

            if let user = authResult?.user {
                print("Successful account creation")

                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Failed to update display name: \(error.localizedDescription)")
                    } else {
                        print("Display name set to \(username)")
                    }
                }

                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "email": email,
                    "username": username,
                    "searchableName": username.lowercased(),
                    "friends": [],
                    "createdAt": Timestamp(),
                ]) { firestoreError in
                    if let firestoreError = firestoreError {
                        print("Error saving user to Firestore: \(firestoreError.localizedDescription)")
                    } else {
                        print("User profile saved to Firestore")
                    }
                }

                completion(true, nil)
            } else {
                print("Creation error: \(String(describing: error?.localizedDescription))")
                completion(false, error)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }

    // ✅ Add this method:
    func addFriend(friendUID: String, completion: @escaping (Error?) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }

        let db = Firestore.firestore()
        let friendshipQuery = db.collection("friendships")
            .whereField("from", isEqualTo: currentUID)
            .whereField("to", isEqualTo: friendUID)

        friendshipQuery.getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }

            if let docs = snapshot?.documents, !docs.isEmpty {
                // Request already exists
                completion(NSError(domain: "", code: 409, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent"]))
                return
            }

            // Create new friend request
            let newRequest = [
                "from": currentUID,
                "to": friendUID,
                "timestamp": Timestamp(date: Date())
            ] as [String: Any]

            db.collection("friendships").addDocument(data: newRequest) { error in
                completion(error)
            }
        }
    }
    
    func fetchFriendRequests() {
        guard let currentUID = user?.uid else { return }

        let db = Firestore.firestore()

        // Fetch requests
        db.collection("friendships")
            .whereField("to", isEqualTo: currentUID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching requests: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }
                var requests: [SearchResultItem] = []

                for doc in docs {
                    let fromUID = doc["from"] as? String ?? ""
                    db.collection("users").document(fromUID).getDocument { userSnap, _ in
                        guard let userData = userSnap?.data() else { return }
                        let request = SearchResultItem(
                            id: fromUID,
                            title: userData["username"] as? String ?? "Unknown",
                            subtitle: userData["email"] as? String,
                            type: .user
                        )
                        requests.append(request)
                        DispatchQueue.main.async {
                            self.friendRequests = requests
                        }
                    }
                }
            }

        // Fetch actual friends
        db.collection("users").document(currentUID).addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }
            let friendUIDs = data["friends"] as? [String] ?? []

            var fetchedFriends: [SearchResultItem] = []

            for uid in friendUIDs {
                db.collection("users").document(uid).getDocument { snap, _ in
                    guard let userData = snap?.data() else { return }
                    let friend = SearchResultItem(
                        id: uid,
                        title: userData["username"] as? String ?? "Unknown",
                        subtitle: userData["email"] as? String,
                        type: .user
                    )
                    fetchedFriends.append(friend)
                    DispatchQueue.main.async {
                        self.friends = fetchedFriends
                    }
                }
            }
        }
    }

//    func acceptFriendRequest(fromUID: String) {
//        guard let currentUID = user?.uid else { return }
//
//        let db = Firestore.firestore()
//
//        // Remove pending request
//        let query = db.collection("friendships")
//            .whereField("from", isEqualTo: fromUID)
//            .whereField("to", isEqualTo: currentUID)
//
//        query.getDocuments { snapshot, error in
//            guard let docs = snapshot?.documents else { return }
//            for doc in docs {
//                doc.reference.delete()
//            }
//
//            // ✅ Only update current user's document
//            let currentUserRef = db.collection("users").document(currentUID)
//
//            currentUserRef.updateData([
//                "friends": FieldValue.arrayUnion([fromUID])
//            ]) { error in
//                if let error = error {
//                    print("Failed to update current user's friends list: \(error.localizedDescription)")
//                } else {
//                    print("Friend request accepted.")
//                }
//            }
//        }
//    }
    func acceptFriendRequest(fromUID: String) {
        guard let currentUID = user?.uid else { return }

        let db = Firestore.firestore()

        // Remove the request document
        let query = db.collection("friendships")
            .whereField("from", isEqualTo: fromUID)
            .whereField("to", isEqualTo: currentUID)

        query.getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            for doc in docs {
                doc.reference.delete()
            }

            // Add each user to the other's friends list
            let currentUserRef = db.collection("users").document(currentUID)
            let fromUserRef = db.collection("users").document(fromUID)

            // Add fromUID to current user's friends
            currentUserRef.updateData([
                "friends": FieldValue.arrayUnion([fromUID])
            ]) { error in
                if let error = error {
                    print("Failed to update current user's friends: \(error.localizedDescription)")
                } else {
                    print("Added \(fromUID) to current user's friends")
                }
            }
            
            // Add currentUID to fromUID's friends
            fromUserRef.updateData([
                "friends": FieldValue.arrayUnion([currentUID])
            ]) { error in
                if let error = error {
                    print("Failed to update request sender's friends: \(error.localizedDescription)")
                } else {
                    print("Added \(currentUID) to request sender's friends")
                    DispatchQueue.main.async {
                        self.fetchFriendRequests()
                    }
                }
            }
        }
    }
}
