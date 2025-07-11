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

class SearchViewModel: ObservableObject {
    @Published var results: [SearchResultItem] = []
    private let db = Firestore.firestore()

    var currentUserID: String? = Auth.auth().currentUser?.uid

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

            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

struct friendView: View {
    @State private var searchText = ""
    @State private var showingCreateGroup = false
    @State private var isEditing = false

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
                    myGroupsSection
                    friendRequestsSection
                }

                searchResultsSection
            }
            .navigationDestination(for: String.self) { groupName in
                GroupDetail(groupName: groupName)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .disabled(myGroups.isEmpty)
                    .foregroundColor(myGroups.isEmpty ? .gray : .blue)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
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
                    auth: auth
                )
            }
            .onChange(of: myGroups) { _, newGroups in
                if newGroups.isEmpty {
                    isEditing = false
                }
            }
            .onAppear {
                searchVM.currentUserID = auth.user?.uid ?? Auth.auth().currentUser?.uid
            }
        }
    }
    
    struct DetailedSearch: View {
        let query: String
        let excludingGroups: [String]
        let dismiss: () -> Void
        @ObservedObject var auth: fireAuth

        @State private var selectedTab = "Accounts"
        @StateObject private var searchVM = SearchViewModel()

        // 👇 New
        @State private var searchText: String = ""

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
                        Button {
                            handleItemSelection(item)
                        } label: {
                            SearchResultRow(item: item)
                        }
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

        private func handleItemSelection(_ item: SearchResultItem) {
            if item.type == .user {
                auth.addFriend(friendUID: item.id) { error in
                    if let error = error {
                        print("Friend request failed: \(error.localizedDescription)")
                    } else {
                        print("Friend request sent to \(item.title)")
                        searchVM.results.removeAll { $0.id == item.id }
                    }
                }
            } else {
                print("Selected group: \(item.title)")
            }
        }
    }
    
    private var myGroupsSection: some View {
        Section(header: Text("My Groups")) {
            if myGroups.isEmpty {
                Text("You haven't joined any groups yet")
                    .foregroundColor(.gray)
            } else {
                ForEach(myGroups, id: \.self) { group in
                    NavigationLink(destination: GroupDetail(groupName: group)) {
                        Text(group)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let groupToDelete = myGroups[index]
                        groupVM.deleteGroup(name: groupToDelete, auth: auth)
                    }
                }
            }
        }
    }

    private var friendRequestsSection: some View {
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
                                .foregroundColor(.blue) // Make request name blue
                            if let email = request.subtitle {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.blue.opacity(0.7)) // Lighter blue for email
                            }
                        }
                        Spacer()
                        if acceptedRequests.contains(request.id) {
                            Text("Accepted")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Button {
                                auth.acceptFriendRequest(fromUID: request.id)
                                acceptedRequests.insert(request.id)

                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    if let index = auth.friendRequests.firstIndex(where: { $0.id == request.id }) {
                                        let accepted = auth.friendRequests.remove(at: index)
                                        if !auth.friends.contains(where: { $0.id == accepted.id }) {
                                            auth.friends.append(accepted)
                                        }
                                        acceptedRequests.remove(request.id)
                                    }
                                }
                            } label: {
                                Text("Accept")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchText.isEmpty {
            Section(header: Text("Results")) {
                if searchVM.results.isEmpty {
                    Text("No results found")
                        .foregroundColor(.gray)
                } else {
                    ForEach(searchVM.results) { item in
                        Button {
                            handleItemSelection(item)
                        } label: {
                            SearchResultRow(item: item)
                        }
                    }
                }
            }
        }
    }

    private func handleItemSelection(_ item: SearchResultItem) {
        if item.type == .user {
            auth.addFriend(friendUID: item.id) { error in
                if let error = error {
                    print("Friend request failed: \(error.localizedDescription)")
                } else {
                    print("Friend request sent to \(item.title)")
                    searchVM.results.removeAll { $0.id == item.id }
                }
            }
        } else {
            withAnimation {
                groupVM.userGroups.append(item.title)
                searchText = ""
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
    @State private var showingSettings = false
    @State private var showingAddMembers = false
    @EnvironmentObject var auth: fireAuth
    @State private var members: [SearchResultItem] = []

    var body: some View {
        List {
            Section(header: Text("Members")) {
                ForEach(members, id: \ .id) { member in
                    Label(member.title, systemImage: "person.fill")
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
            GroupSettings(groupName: groupName)
        }
        .sheet(isPresented: $showingAddMembers) {
            AddMembersView(groupName: groupName) {
                fetchMembers()
            }
            .environmentObject(auth)
        }
        .onAppear {
            fetchMembers()
        }
    }

    private func fetchMembers() {
        let db = Firestore.firestore()
        db.collection("groups").whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else { return }
            let data = doc.data()
            let memberIDs = data["members"] as? [String] ?? []
            let creatorID = data["creator"] as? String

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

                // Preserve creator at the top if sorting is changed in the future
                fetchedMembers.sort {
                    $0.title.contains("(creator)") && !$1.title.contains("(creator)")
                }

                self.members = fetchedMembers
            }
        }
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

            // Step 1: Add friend to group document
            db.collection("groups").document(groupID).updateData([
                "members": FieldValue.arrayUnion([friendID])
            ]) { error in
                if let error = error {
                    print("Error adding member to group: \(error.localizedDescription)")
                    return
                }

                // Step 2: Add group name to friend's user document
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
    @State private var notificationsEnabled = true
    @State private var isPrivate = false
    @State private var totalScreenTime = true
    @State private var socialMediaTime = true
    @State private var habitsScore = true

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
            }
            .navigationBarTitleDisplayMode(.inline)
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
