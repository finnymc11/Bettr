//
//  Leaderboard.swift
//
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Search Result Enum & Model

enum SearchResultType {
    case user
    case group
}

struct SearchResultItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String? // email for users
    let type: SearchResultType
}

// MARK: - Group ViewModel

class GroupViewModel: ObservableObject {
    @Published var allGroups: [String] = []
    private var db = Firestore.firestore()

    init() {
        fetchGroups()
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

    func addGroup(name: String, completion: @escaping (Error?) -> Void) {
        let newGroup: [String: Any] = [
            "name": name,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("groups").addDocument(data: newGroup) { error in
            if let error = error {
                print("Firestore error: \(error.localizedDescription)")
            } else {
                print("Successfully added group: \(name)")
            }
            completion(error)
        }
    }
}

// MARK: - Search ViewModel

//class SearchViewModel: ObservableObject {
//    @Published var results: [SearchResultItem] = []
//    private let db = Firestore.firestore()
//
//    func search(for text: String, excludingGroups: [String]) {
//        guard !text.isEmpty else {
//            results = []
//            return
//        }
//
//        var combined: [SearchResultItem] = []
//
//        // Search users
//        db.collection("users")
//            .whereField("searchableName", isEqualTo: text.lowercased())
//            .getDocuments { userSnapshot, _ in
//                if let userDocs = userSnapshot?.documents {
//                    let users = userDocs.map { doc -> SearchResultItem in
//                        let data = doc.data()
//                        return SearchResultItem(
//                            id: doc.documentID,
//                            title: data["username"] as? String ?? "Unnamed",
//                            subtitle: data["email"] as? String,
//                            type: .user
//                        )
//                    }
//                    combined.append(contentsOf: users)
//                }
//
//                // Search groups
//                self.db.collection("groups")
//                    .order(by: "createdAt", descending: true)
//                    .getDocuments { groupSnapshot, _ in
//                        if let groupDocs = groupSnapshot?.documents {
//                            let groups = groupDocs.compactMap { doc -> SearchResultItem? in
//                                let name = doc.data()["name"] as? String ?? ""
//                                guard name.lowercased().contains(text.lowercased()),
//                                      !excludingGroups.contains(name)
//                                else { return nil }
//
//                                return SearchResultItem(
//                                    id: doc.documentID,
//                                    title: name,
//                                    subtitle: nil,
//                                    type: .group
//                                )
//                            }
//                            combined.append(contentsOf: groups)
//                        }
//
//                        DispatchQueue.main.async {
//                            self.results = combined
//                        }
//                    }
//            }
//    }
//}

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
                        // 🔒 Exclude current user
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

// MARK: - Search Result Row View

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

// MARK: - Leader View

struct leaderView: View {
    @State private var searchText = ""
    @State private var myGroups: [String] = []
    @State private var showingCreateGroup = false
    @State private var isEditing = false

    @State private var path = NavigationPath()
    @State private var selectedGroup: String? = nil
    @State private var acceptedRequests: Set<String> = []
    
    @State private var showingDetailedSearch = false

    @ObservedObject private var groupVM = GroupViewModel()
    @ObservedObject private var searchVM = SearchViewModel()
    @EnvironmentObject var auth: fireAuth

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
                    myGroups.append(newGroup)
                    selectedGroup = newGroup
                    path.append(newGroup) // Push to navigation
                }
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
//            .onAppear {
//                if !myGroups.contains("Test Group") {
//                    myGroups.append("Test Group")
//                }
//            }
        }
    }
    
//    struct DetailedSearch: View {
//        let query: String
//        let excludingGroups: [String]
//        let dismiss: () -> Void
//        @ObservedObject var auth: fireAuth
//
//        @State private var selectedTab = "Accounts"
//        @StateObject private var searchVM = SearchViewModel()
//
//        var body: some View {
//            NavigationView {
//                VStack {
//                    Picker("Search Type", selection: $selectedTab) {
//                        Text("Accounts").tag("Accounts")
//                        Text("Groups").tag("Groups")
//                    }
//                    .pickerStyle(.segmented)
//                    .padding()
//
//                    List {
//                        ForEach(filteredResults) { item in
//                            Button {
//                                handleItemSelection(item)
//                            } label: {
//                                SearchResultRow(item: item)
//                            }
//                        }
//
//                        if filteredResults.isEmpty {
//                            Text("No results found.")
//                                .foregroundColor(.gray)
//                                .padding()
//                        }
//                    }
//                    .listStyle(.plain)
//                }
//                .navigationTitle("Search Results")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .navigationBarLeading) {
//                        Button("Close") {
//                            dismiss()
//                        }
//                    }
//                }
//                .onAppear {
//                    searchVM.currentUserID = auth.user?.uid
//                    searchVM.search(for: query, excludingGroups: excludingGroups)
//                }
//            }
//        }
//
//        private var filteredResults: [SearchResultItem] {
//            searchVM.results.filter { selectedTab == "Accounts" ? $0.type == .user : $0.type == .group }
//        }
//
//        private func handleItemSelection(_ item: SearchResultItem) {
//            if item.type == .user {
//                auth.addFriend(friendUID: item.id) { error in
//                    if let error = error {
//                        print("Friend request failed: \(error.localizedDescription)")
//                    } else {
//                        print("Friend request sent to \(item.title)")
//                        searchVM.results.removeAll { $0.id == item.id }
//                    }
//                }
//            } else {
//                // Groups — You can extend this to add to user's groups if needed
//                print("Selected group: \(item.title)")
//            }
//        }
//    }
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
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Search Results")
                .navigationBarTitleDisplayMode(.inline)
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
                    searchText = query // 👈 This seeds the initial search text
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



    // MARK: - Subviews
    
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
                    myGroups.remove(atOffsets: indexSet)
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
                // Show current friends
                ForEach(auth.friends) { friend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(friend.title).bold()
                            if let email = friend.subtitle {
                                Text(email).font(.subheadline).foregroundColor(.gray)
                            }
                        }
                    }
                }

                // Show pending requests in blue
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

    // MARK: - Logic

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
                myGroups.append(item.title)
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

                viewModel.addGroup(name: groupName) { error in
                    if let error = error {
                        print("Error adding group: \(error.localizedDescription)")
                    } else {
                        onGroupCreated(groupName)
                        dismiss()
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

    let members = ["Finbar", "CJ"] // Static for now

    var body: some View {
        List {
            Section(header: Text("Members")) {
                ForEach(members, id: \.self) { member in
                    Label(member, systemImage: "person.fill")
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
    }
}

struct GroupSettings: View {
    var groupName: String
    @State private var notificationsEnabled = true
    @State private var isPrivate = false
    @State private var allowNewMembers = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Settings for \(groupName)")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(.green)
                    Toggle("Private Group", isOn: $isPrivate)
                        .tint(.green)
                    Toggle("Allow New Members", isOn: $allowNewMembers)
                        .tint(.green)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
