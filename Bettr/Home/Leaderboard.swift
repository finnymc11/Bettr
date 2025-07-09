//
//  Leaderboard.swift
//
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Foundation
import FirebaseFirestore

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

struct leaderView: View {
    @State private var searchText = ""
    @State private var myGroups: [String] = []
    @State private var showingCreateGroup = false
    @State private var isEditing = false
    @ObservedObject private var viewModel = GroupViewModel()
    
    var filteredItems: [String] {
        if searchText.isEmpty {
            return []
        } else {
            return viewModel.allGroups
                .filter { $0.localizedCaseInsensitiveContains(searchText) }
                .filter { !myGroups.contains($0) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // My Groups Section
                Section(header: Text("My Groups")) {
                    ForEach(myGroups, id: \.self) { group in
                        NavigationLink(destination: GroupDetail(groupName: group)) {
                            Text(group)
                        }
                    }
                    .onDelete { indexSet in
                        myGroups.remove(atOffsets: indexSet)
                    }
                }

                // Search Results Section
                if !searchText.isEmpty {
                    Section(header: Text("Results")) {
                        ForEach(filteredItems, id: \.self) { item in
                            Button(action: {
                                withAnimation {
                                    myGroups.append(item)
                                    searchText = ""
                                }
                            }) {
                                Text(item)
                            }
                        }

                        if filteredItems.isEmpty {
                            Text("No results found")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Friends")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Find friends & groups"
            )
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
                // 👇 Pass a callback to add new group to myGroups
                CreateGroup(viewModel: viewModel) { newGroup in
                    myGroups.append(newGroup)
                }
            }
            .onChange(of: myGroups) { _, newGroups in
                if newGroups.isEmpty {
                    isEditing = false
                }
            }
            .onAppear {
                if !myGroups.contains("Test Group") {
                    myGroups.append("Test Group")
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

    // Dummy members
    let members = ["Finbar", "CJ"]

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


#Preview {
    Home()
}
