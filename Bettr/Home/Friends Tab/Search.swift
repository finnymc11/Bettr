//
//  Search.swift
//  Bettr
//
//  Created by Finbar McCarron on 7/15/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum SearchResultType {
    case user
    case group
}

struct SearchResultItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let type: SearchResultType
}

struct SearchResultsSection: View {
    var searchText: String
    var onGroupSelected: (String) -> Void

    @EnvironmentObject var auth: fireAuth
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var searchVM: SearchViewModel

    var body: some View {
        if !searchText.isEmpty {
            Section(header: Text("Results")) {
                if searchVM.results.isEmpty {
                    Text("No results found")
                        .foregroundColor(.gray)
                } else {
                    ForEach(searchVM.results) { item in
                        switch item.type {
                        case .user:
                            SearchResultRow(
                                item: item,
                                onAddFriend: {
                                    auth.addFriend(friendUID: item.id) { error in
                                        if let error = error {
                                            print("Friend request failed: \(error.localizedDescription)")
                                        } else {
                                            print("Friend request sent to \(item.title)")
                                            DispatchQueue.main.async {
                                                searchVM.sentRequests.insert(item.id)
                                            }
                                        }
                                    }
                                },
                                requestSent: searchVM.sentRequests.contains(item.id),
                                isAlreadyFriend: auth.friends.contains(where: { $0.id == item.id })
                            )

                        case .group:
                            let alreadyJoined = groupVM.userGroups.contains(item.title)
                            Button {
                                onGroupSelected(item.title)
                            } label: {
                                HStack {
                                    Label {
                                        Text(item.title)
                                    } icon: {
                                        Image(systemName: "person.3.fill")
                                            .foregroundColor(.purple)
                                    }

                                    Spacer()

                                    if alreadyJoined {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.blue)
                                            .font(.body)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct DetailedSearch: View {
    let query: String
    let excludingGroups: [String]
    let dismiss: () -> Void
    let onGroupSelected: (String) -> Void
    @ObservedObject var auth: fireAuth
    @ObservedObject var searchVM: SearchViewModel
    @State private var selectedTab = "Accounts"
    @State private var searchText: String = ""
    @ObservedObject var groupVM: GroupViewModel

    var body: some View {
        NavigationStack {
            List {
                Picker("Search Type", selection: $selectedTab) {
                    Text("Accounts").tag("Accounts")
                    Text("Groups").tag("Groups")
                }
                .pickerStyle(.segmented)
                .padding(.vertical)
                .listRowSeparator(.hidden)

                ForEach(filteredResults) { item in
                    DetailedSearchRow(
                        item: item,
                        auth: auth,
                        searchVM: searchVM,
                        groupVM: groupVM,
                        onDismiss: dismiss,
                        onGroupSelected: onGroupSelected
                    )
                }

                if filteredResults.isEmpty {
                    Text("No results found.")
                        .foregroundColor(.gray)
                        .padding()
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search friends & groups"
            )
            .onChange(of: searchText) { _, newValue in
                searchVM.search(for: newValue, excludingGroups: excludingGroups)
            }
            .onAppear {
                searchVM.currentUserID = auth.user?.uid
                searchText = query
                searchVM.search(for: query, excludingGroups: excludingGroups)
            }
        }
    }

    private var filteredResults: [SearchResultItem] {
        searchVM.results.filter { selectedTab == "Accounts" ? $0.type == .user : $0.type == .group }
    }
}

struct DetailedSearchRow: View {
    let item: SearchResultItem
    @ObservedObject var auth: fireAuth
    @ObservedObject var searchVM: SearchViewModel
    @ObservedObject var groupVM: GroupViewModel
    let onDismiss: () -> Void
    let onGroupSelected: (String) -> Void

    var body: some View {
        switch item.type {
        case .user:
            Button {
                sendFriendRequest()
            } label: {
                SearchResultRow(
                    item: item,
                    onAddFriend: {
                        sendFriendRequest()
                    },
                    requestSent: searchVM.sentRequests.contains(item.id),
                    isAlreadyFriend: auth.friends.contains(where: { $0.id == item.id })
                )
            }

        case .group:
            groupRow
        }
    }

    private var groupRow: some View {
        let alreadyJoined = groupVM.userGroups.contains(item.title)

        return HStack {
            Label {
                Text(item.title)
            } icon: {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.purple)
            }

            Spacer()

            Button {
                onGroupSelected(item.title)
            } label: {
                HStack {
                    Label {
                        Text(item.title)
                    } icon: {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.purple)
                    }

                    Spacer()

                    if alreadyJoined {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

        }
        .padding(.vertical, 4)
    }

    private func sendFriendRequest() {
        auth.addFriend(friendUID: item.id) { error in
            if let error = error {
                print("Friend request failed: \(error.localizedDescription)")
            } else {
                print("Friend request sent to \(item.title)")
                DispatchQueue.main.async {
                    searchVM.sentRequests.insert(item.id)
                }
            }
        }
    }
    
    private func joinGroup() {
        groupVM.joinGroup(groupID: item.id, groupName: item.title) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    if !groupVM.userGroups.contains(item.title) {
                        groupVM.userGroups.append(item.title)
                    }
                }
            case .failure(let error):
                print("Failed to join group: \(error.localizedDescription)")
            }
        }
    }
}

class SearchViewModel: ObservableObject {
    @Published var results: [SearchResultItem] = []
    @Published var sentRequests: Set<String> = []
    @Published var friends: Set<String> = []

    private let db = Firestore.firestore()

    var currentUserID: String? = Auth.auth().currentUser?.uid
    
    func loadSentRequests() {
        guard let currentUserID = currentUserID else { return }

        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUserID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Failed to load sent friend requests: \(error.localizedDescription)")
                    return
                }

                let sentToIDs = snapshot?.documents.compactMap { $0.data()["to"] as? String } ?? []
                DispatchQueue.main.async {
                    self.sentRequests = Set(sentToIDs)
                    print("Sent friend requests: \(self.sentRequests)")
                }
            }
    }

    func search(for text: String, excludingGroups: [String]) {
        guard !text.isEmpty else {
            results = []
            return
        }

        var combined: [SearchResultItem] = []
        db.collection("users")
            .whereField("searchableName", isEqualTo: text.lowercased())
            .getDocuments { userSnapshot, _ in
                if let userDocs = userSnapshot?.documents {
                    let users = userDocs.compactMap { doc -> SearchResultItem? in
                        guard doc.documentID != self.currentUserID else { return nil }
                        let data = doc.data()
                        return SearchResultItem(
                            id: doc.documentID,
                            title: data["username"] as? String ?? "Unnamed",
                            subtitle: data["email"] as? String,
                            type: .user
                        )
                    }
                    combined.append(contentsOf: users)
                }

                self.db.collection("groups")
                    .order(by: "createdAt", descending: true)
                    .getDocuments { groupSnapshot, _ in
                        if let groupDocs = groupSnapshot?.documents {
                            let groups = groupDocs.compactMap { doc -> SearchResultItem? in
                                let name = doc.data()["name"] as? String ?? ""
                                guard name.lowercased().contains(text.lowercased()) else {
                                    return nil
                                }

                                return SearchResultItem(
                                    id: doc.documentID,
                                    title: name,
                                    subtitle: nil,
                                    type: .group
                                )
                            }
                            combined.append(contentsOf: groups)
                        }

                        DispatchQueue.main.async {
                            self.results = combined
                        }
                    }
            }
    }
}

struct SearchResultRow: View {
    let item: SearchResultItem
    let onAddFriend: () -> Void
    let requestSent: Bool
    let isAlreadyFriend: Bool

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            } icon: {
                Image(systemName: item.type == .user ? "person.fill" : "person.3.fill")
                    .foregroundColor(item.type == .user ? .blue : .purple)
            }

            Spacer()

            if isAlreadyFriend {
                EmptyView()
            } else if requestSent {
                Text("Request Sent")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            } else {
                Button(action: onAddFriend) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

class GroupViewModel: ObservableObject {
    @Published var allGroups: [String] = []
    @Published var userGroups: [String] = []
    private var db = Firestore.firestore()

    init() {
        fetchGroups()
        fetchUserGroups()
    }

    func fetchGroups() {
        db.collection("groups").order(by: "createdAt", descending: true).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching groups: \(error.localizedDescription)")
                return
            }

            self.allGroups = snapshot?.documents.compactMap {
                $0.data()["name"] as? String
            } ?? []
        }
    }
    
    func fetchUserGroups() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(currentUID).addSnapshotListener { snapshot, error in
            if let error = error {
                print("Failed to fetch user groups: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data() {
                let groups = data["groups"] as? [String] ?? []
                DispatchQueue.main.async {
                    self.userGroups = groups
                }
            }
        }
    }

    func addGroup(name: String, completion: @escaping (Result<(id: String, name: String), Error>) -> Void) {
        let currentUID = Auth.auth().currentUser?.uid ?? ""
        let newGroup: [String: Any] = [
            "name": name,
            "createdAt": Timestamp(date: Date()),
            "members": [currentUID],
            "creator": currentUID
        ]

        let docRef = db.collection("groups").document()
        docRef.setData(newGroup) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self.db.collection("users").document(currentUID).updateData([
                "groups": FieldValue.arrayUnion([name])
            ]) { userUpdateError in
                if let userUpdateError = userUpdateError {
                    print("Failed to update user's group list: \(userUpdateError.localizedDescription)")
                    completion(.failure(userUpdateError))
                } else {
                    self.fetchUserGroups()
                    completion(.success((id: docRef.documentID, name: name)))
                }
            }
        }
    }
    func deleteGroup(name: String, auth: fireAuth) {
        auth.deleteGroup(name: name) { success in
            if success {
                DispatchQueue.main.async {
                    self.userGroups.removeAll { $0 == name }
                }
            }
        }
    }
}

extension GroupViewModel {
    func joinGroup(groupID: String, groupName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No current user"])))
            return
        }
        
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(currentUID)
        
        groupRef.updateData([
            "members": FieldValue.arrayUnion([currentUID])
        ]) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            userRef.updateData([
                "groups": FieldValue.arrayUnion([groupName])
            ]) { userError in
                if let userError = userError {
                    completion(.failure(userError))
                } else {
                    self.fetchUserGroups()
                    completion(.success(()))
                }
            }
        }
    }
}
