//
//  Friends.swift
//
//
//  Created by CJ Balmaceda on 6/20/25.
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
                                guard name.lowercased().contains(text.lowercased()),
                                      !excludingGroups.contains(name)
                                else { return nil }

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

struct DetailedSearchRow: View {
    let item: SearchResultItem
    @ObservedObject var auth: fireAuth
    @ObservedObject var searchVM: SearchViewModel
    @ObservedObject var groupVM: GroupViewModel
    let onDismiss: () -> Void

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

            if alreadyJoined {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            } else {
                Button {
                    joinGroup()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
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

struct friendView: View {
    @State private var searchText = ""
    @State private var showingCreateGroup = false
    @State private var path = NavigationPath()
    @State private var selectedGroup: String? = nil
    @State private var acceptedRequests: Set<String> = []
    @State private var selectedFriend: SearchResultItem? = nil
    @State private var showingDetailedSearch = false

    @ObservedObject private var groupVM = GroupViewModel()
    @ObservedObject private var searchVM = SearchViewModel()
    @EnvironmentObject var auth: fireAuth
    
    private var myGroups: [String] { groupVM.userGroups }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if searchText.isEmpty {
                    MyGroupsSection(myGroups: myGroups, path: $path)
                    FriendRequestsSection(selectedFriend: $selectedFriend)
                        .environmentObject(auth)
                }

                SearchResultsSection(searchText: searchText)
                    .environmentObject(auth)
                    .environmentObject(groupVM)
                    .environmentObject(searchVM)
            }
            .navigationDestination(for: String.self) { groupName in
                GroupDetail(
                    groupName: groupName,
                    onLeaveGroup: {
                        path = NavigationPath()
                    }
                )
                .environmentObject(auth)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Friends")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Find friends & groups"
            )
            .onChange(of: searchText) { _, newValue in
                searchVM.search(for: newValue, excludingGroups: myGroups)
            }
            .onSubmit(of: .search) {
                showingDetailedSearch = true
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroup(viewModel: groupVM) { newGroup in
                    selectedGroup = newGroup
                    path.append(newGroup)
                }
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailView(friend: friend)
                    .environmentObject(auth)
            }
            .fullScreenCover(isPresented: $showingDetailedSearch) {
                DetailedSearch(
                    query: searchText,
                    excludingGroups: myGroups,
                    dismiss: { showingDetailedSearch = false },
                    auth: auth,
                    searchVM: searchVM,
                    groupVM: groupVM
                )
            }
            .onAppear {
                searchVM.currentUserID = auth.user?.uid ?? Auth.auth().currentUser?.uid
                searchVM.loadSentRequests()
            }
        }
    }
}

struct DetailedSearch: View {
    let query: String
    let excludingGroups: [String]
    let dismiss: () -> Void
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
                        onDismiss: dismiss
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


struct MyGroupsSection: View {
    var myGroups: [String]
    @Binding var path: NavigationPath

    var body: some View {
        Section(header: Text("My Groups")) {
            if myGroups.isEmpty {
                Text("You haven't joined any groups yet")
                    .foregroundColor(.gray)
            } else {
                ForEach(myGroups, id: \.self) { group in
                    Button {
                        path.append(group)
                    } label: {
                        Text(group)
                    }
                }
            }
        }
    }
}

struct FriendRequestsSection: View {
    @EnvironmentObject var auth: fireAuth
    @Binding var selectedFriend: SearchResultItem?

    var body: some View {
        Section(header: Text("Friends")) {
            if auth.friends.isEmpty && auth.friendRequests.isEmpty {
                Text("No friends yet")
                    .foregroundColor(.gray)
            } else {
                ForEach(auth.friends) { friend in
                    Button {
                        selectedFriend = friend
                    } label: {
                        VStack(alignment: .leading) {
                            Text(friend.title).bold()
                            if let email = friend.subtitle {
                                Text(email).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }
                ForEach(auth.friendRequests) { request in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(request.title)
                                .bold()
                                .foregroundColor(.blue)
                            if let email = request.subtitle {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.blue.opacity(0.7))
                            }
                        }
                        .contentShape(Rectangle())

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                auth.acceptFriendRequest(fromUID: request.id)
                                if let index = auth.friendRequests.firstIndex(where: { $0.id == request.id }) {
                                    let accepted = auth.friendRequests.remove(at: index)
                                    if !auth.friends.contains(where: { $0.id == accepted.id }) {
                                        auth.friends.append(accepted)
                                    }
                                }
                            } label: {
                                Text("Accept")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)

                            Button {
                                auth.declineFriendRequest(fromUID: request.id)
                                if let index = auth.friendRequests.firstIndex(where: { $0.id == request.id }) {
                                    auth.friendRequests.remove(at: index)
                                }
                            } label: {
                                Text("Decline")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

struct SearchResultsSection: View {
    @EnvironmentObject var auth: fireAuth
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var searchVM: SearchViewModel
    var searchText: String

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
                                    Button {
                                        groupVM.joinGroup(groupID: item.id, groupName: item.title) { result in
                                            switch result {
                                            case .success:
                                                DispatchQueue.main.async {
                                                    withAnimation {
                                                        if !groupVM.userGroups.contains(item.title) {
                                                            groupVM.userGroups.append(item.title)
                                                        }
                                                    }
                                                }
                                            case .failure(let error):
                                                print("Failed to join group: \(error.localizedDescription)")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }
}


struct CreateGroup: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName: String = ""
    @ObservedObject var viewModel: GroupViewModel
    var onGroupCreated: (String) -> Void

    var body: some View {
        Form {
            Section(header: Text("Group Name")) {
                TextField("Enter group name", text: $groupName)
            }

            Button("Create") {
                guard !groupName.isEmpty else {
                    print("Group name is empty")
                    return
                }
                viewModel.addGroup(name: groupName) { result in
                    switch result {
                    case .success(let group):
                        onGroupCreated(group.name)
                        dismiss()
                    case .failure(let error):
                        print("Error adding group: \(error.localizedDescription)")
                    }
                }
            }
        }
        .navigationTitle("Create Group")
    }
}

struct GroupDetail: View {
    var groupName: String
    var onLeaveGroup: (() -> Void)? = nil
    @State private var showingSettings = false
    @State private var showingAddMembers = false
    @EnvironmentObject var auth: fireAuth
    @State private var members: [SearchResultItem] = []
    @State private var creatorID: String?
    @State private var groupDocID: String?

    var body: some View {
        List {
            Section(header: Text("Members")) {
                ForEach(members.filter { $0.id != auth.user?.uid }, id: \.id) { member in
                    Label(member.title, systemImage: "person.fill")
                }
                .onDelete(perform: canCurrentUserRemoveMembers ? removeMembers : nil)

                if let currentUser = members.first(where: { $0.id == auth.user?.uid }) {
                    Label(currentUser.title, systemImage: "person.fill")
                        .foregroundColor(.gray)
                }
            }

            Section {
                Button(action: {
                    showingAddMembers = true
                }) {
                    HStack {
                        Spacer()
                        Label("Add Members", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(groupName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            GroupSettings(
                groupName: groupName,
                onLeaveGroup: {
                    showingSettings = false
                    onLeaveGroup?()
                }
            )
            .environmentObject(auth)
        }
        .sheet(isPresented: $showingAddMembers) {
            AddMembersView(groupName: groupName) {
                fetchMembers()
            }
            .environmentObject(auth)
        }
        .onAppear {
            fetchGroupData()
            fetchMembers()
        }
    }

    private var canCurrentUserRemoveMembers: Bool {
        auth.user?.uid == creatorID
    }

    private func fetchGroupData() {
        let db = Firestore.firestore()
        db.collection("groups").whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else { return }
            groupDocID = doc.documentID
            let data = doc.data()
            creatorID = data["creator"] as? String
        }
    }

    private func fetchMembers() {
        let db = Firestore.firestore()
        db.collection("groups").whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else { return }
            let data = doc.data()
            let memberIDs = data["members"] as? [String] ?? []
            creatorID = data["creator"] as? String

            let userRef = db.collection("users")
            userRef.whereField(FieldPath.documentID(), in: memberIDs).getDocuments { userSnapshot, error in
                guard let docs = userSnapshot?.documents else { return }

                var fetchedMembers: [SearchResultItem] = docs.map { doc in
                    let userData = doc.data()
                    let isCreator = doc.documentID == creatorID
                    let username = userData["username"] as? String ?? "Unnamed"
                    return SearchResultItem(
                        id: doc.documentID,
                        title: isCreator ? "\(username) (creator)" : username,
                        subtitle: userData["email"] as? String,
                        type: .user
                    )
                }

                fetchedMembers.sort {
                    $0.title.contains("(creator)") && !$1.title.contains("(creator)")
                }

                self.members = fetchedMembers
            }
        }
    }

    private func removeMembers(at offsets: IndexSet) {
        guard let groupDocID = groupDocID else { return }
        let db = Firestore.firestore()

        let membersToRemove = offsets.map { members[$0] }

        for member in membersToRemove {
            if member.id == creatorID { continue }

            db.collection("groups").document(groupDocID).updateData([
                "members": FieldValue.arrayRemove([member.id])
            ]) { error in
                if let error = error {
                    print("Failed to remove member \(member.title): \(error.localizedDescription)")
                } else {
                    db.collection("users").document(member.id).updateData([
                        "groups": FieldValue.arrayRemove([groupName])
                    ]) { userError in
                        if let userError = userError {
                            print("Failed to update user \(member.title): \(userError.localizedDescription)")
                        }
                    }
                }
            }
        }

        members.remove(atOffsets: offsets)
    }
}

struct AddMembersView: View {
    var groupName: String
    var onAddComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var auth: fireAuth

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Your Friends")) {
                    ForEach(auth.friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.title)
                                    .bold()
                                if let email = friend.subtitle {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Button {
                                addMemberToGroup(friendID: friend.id)
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                    }

                    if auth.friends.isEmpty {
                        Text("You have no friends to add.")
                            .foregroundColor(.gray)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemGray6
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }

    private func addMemberToGroup(friendID: String) {
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").whereField("name", isEqualTo: groupName)

        groupRef.getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else { return }

            let groupID = doc.documentID

            db.collection("groups").document(groupID).updateData([
                "members": FieldValue.arrayUnion([friendID])
            ]) { error in
                if let error = error {
                    print("Error adding member to group: \(error.localizedDescription)")
                    return
                }

                db.collection("users").document(friendID).updateData([
                    "groups": FieldValue.arrayUnion([groupName])
                ]) { userError in
                    if let userError = userError {
                        print("Error adding group to user's list: \(userError.localizedDescription)")
                    } else {
                        print("Successfully added \(friendID) to \(groupName) and updated their group list")
                        onAddComplete()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GroupSettings: View {
    var groupName: String
    var onLeaveGroup: (() -> Void)? = nil
    @EnvironmentObject var auth: fireAuth
    @Environment(\.dismiss) var dismiss
    
    @State private var notificationsEnabled = true
    @State private var isPrivate = false
    @State private var totalScreenTime = true
    @State private var socialMediaTime = true
    @State private var habitsScore = true
    
    @State private var groupDocID: String?
    @State private var creatorID: String?
    @State private var members: [String] = []
    
    @State private var shouldTriggerOnLeave = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Settings for \(groupName)")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(.green)
                    Toggle("Private Group", isOn: $isPrivate)
                        .tint(.green)
                    Toggle("Share total screen time", isOn: $totalScreenTime)
                        .tint(.green)
                    Toggle("Share screen time on social media", isOn: $socialMediaTime)
                        .tint(.green)
                    Toggle("Share my digital habits score", isOn: $habitsScore)
                        .tint(.green)
                }
                
                if let currentUID = auth.user?.uid {
                    if creatorID == currentUID {
                        Section {
                            Button(role: .destructive) {
                                deleteGroup()
                            } label: {
                                Label("Delete Group", systemImage: "trash")
                            }
                        }
                    } else if members.contains(currentUID) {
                        Section {
                            Button(role: .destructive) {
                                leaveGroup(currentUID: currentUID)
                            } label: {
                                Label("Leave Group", systemImage: "arrowshape.turn.up.left")
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: loadGroupData)
            .onDisappear {
                if shouldTriggerOnLeave {
                    onLeaveGroup?()
                }
            }
        }
    }
    
    private func loadGroupData() {
        let db = Firestore.firestore()
        db.collection("groups").whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else {
                print("Group not found")
                return
            }
            groupDocID = doc.documentID
            let data = doc.data()
            creatorID = data["creator"] as? String
            members = data["members"] as? [String] ?? []
        }
    }
    
    private func leaveGroup(currentUID: String) {
        guard let groupDocID = groupDocID else { return }
        let db = Firestore.firestore()

        db.collection("groups").document(groupDocID).updateData([
            "members": FieldValue.arrayRemove([currentUID])
        ]) { error in
            if let error = error {
                print("Failed to leave group: \(error.localizedDescription)")
            } else {
                print("Successfully left group")

                db.collection("users").document(currentUID).updateData([
                    "groups": FieldValue.arrayRemove([groupName])
                ])
                dismiss()
                shouldTriggerOnLeave = true
            }
        }
    }
    private func deleteGroup() {
        guard let groupDocID = groupDocID else { return }
        let db = Firestore.firestore()

        db.collection("groups").document(groupDocID).getDocument { snapshot, error in
            guard let doc = snapshot, doc.exists, let data = doc.data() else {
                print("Failed to get group data for deletion")
                return
            }

            let members = data["members"] as? [String] ?? []

            db.collection("groups").document(groupDocID).delete { error in
                if let error = error {
                    print("Failed to delete group: \(error.localizedDescription)")
                    return
                }

                print("Group deleted successfully")

                let batch = db.batch()
                for memberUID in members {
                    let memberRef = db.collection("users").document(memberUID)
                    batch.updateData([
                        "groups": FieldValue.arrayRemove([groupName])
                    ], forDocument: memberRef)
                }

                batch.commit { batchError in
                    if let batchError = batchError {
                        print("Failed to update members' groups: \(batchError.localizedDescription)")
                    } else {
                        print("Removed group from all members' group lists")
                        DispatchQueue.main.async {
                            dismiss()
                            shouldTriggerOnLeave = true
                        }
                    }
                }
            }
        }
    }
}

struct FriendDetailView: View {
    let friend: SearchResultItem
    @EnvironmentObject var auth: fireAuth
    @Environment(\.dismiss) var dismiss

    @State private var shareScreenTime = true
    @State private var shareSocialMedia = true
    @State private var shareHabitsScore = true

    var body: some View {
        Form {
            Section(header: Text("Privacy Settings")) {
                Toggle("Share screen time", isOn: $shareScreenTime)
                Toggle("Share social media time", isOn: $shareSocialMedia)
                Toggle("Share habits score", isOn: $shareHabitsScore)
            }

            Section {
                Button(role: .destructive) {
                    auth.removeFriend(uid: friend.id)
                    dismiss()
                } label: {
                    Label("Remove Friend", systemImage: "trash")
                }
            }
        }
        .navigationTitle(friend.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
