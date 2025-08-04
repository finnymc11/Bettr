//
//  Friends.swift
//  Bettr
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        if let error = error {
            print("Notification error: \(error)")
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
                SearchResultsSection(searchText: searchText, onGroupSelected: { group in
                    selectedGroup = group
                    path.append(group)
                })
                .environmentObject(auth)
                .environmentObject(groupVM)
                .environmentObject(searchVM)
            }
            .navigationDestination(for: String.self) { groupName in
                GroupDetail(
                    groupName: groupName,
                    onLeaveGroup: {
                        path = NavigationPath()
                    },
                    isJoinable: true
                )
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
                    onGroupSelected: { group in
                        selectedGroup = group
                        path.append(group)
                        showingDetailedSearch = false
                    },
                    auth: auth,
                    searchVM: searchVM,
                    groupVM: groupVM
                )
            }
            .onAppear {
                searchVM.currentUserID = auth.user?.uid ?? Auth.auth().currentUser?.uid
                searchVM.loadSentRequests()
                requestNotificationPermission()
            }
        }
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
