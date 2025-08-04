//
//  Groups.swift
//  Bettr
//
//  Created by Finbar McCarron on 7/15/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct GroupDetail: View {
    var groupName: String
    var onLeaveGroup: (() -> Void)? = nil
    var isJoinable: Bool = false
    
    @State private var showingSettings = false
    @State private var showingAddMembers = false
    @EnvironmentObject var auth: fireAuth
    @State private var members: [SearchResultItem] = []
    @State private var creatorID: String?
    @State private var groupDocID: String?
    @State private var isMember = false
    @State private var membershipChecked = false
    @State private var isPrivateGroup: Bool = false
    @State private var hasSentJoinRequest = false
    @State private var joinRequests: [SearchResultItem] = []

    var body: some View {
        List {
            Section(header: Text("Members")) {
                ForEach(members, id: \.id) { member in
                    Label(member.title, systemImage: "person.fill")
                        .foregroundColor(member.id == creatorID ? .gray : .primary)
                }
                .onDelete(perform: canCurrentUserRemoveMembers ? removeMembers : nil)
            }

            if canCurrentUserRemoveMembers {
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
            if auth.user?.uid == creatorID && !joinRequests.isEmpty {
                Section(header: Text("Join Requests")) {
                    ForEach(joinRequests, id: \.id) { request in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(request.title).bold()
                                if let email = request.subtitle {
                                    Text(email).font(.subheadline).foregroundColor(.blue.opacity(0.7))
                                }
                            }

                            Spacer()

                            Button("Accept") {
                                acceptJoinRequest(request)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)

                            Button("Decline") {
                                declineJoinRequest(request)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(groupName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if membershipChecked {
                    if !isMember && isJoinable {
                        if isPrivateGroup {
                            Text(hasSentJoinRequest ? "Request Sent" : "Request to Join")
                                .foregroundColor(hasSentJoinRequest ? .gray : .blue)
                                .onTapGesture {
                                    if !hasSentJoinRequest {
                                        requestToJoinGroup()
                                    }
                                }
                        } else {
                            Button("Join") {
                                joinGroup()
                            }
                        }
                    } else if isMember {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "ellipsis")
                        }
                    }
                } else {
                    ProgressView().frame(width: 20, height: 20)
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
    
    private func acceptJoinRequest(_ request: SearchResultItem) {
        guard let groupDocID = groupDocID else { return }
        let db = Firestore.firestore()

        let groupRef = db.collection("groups").document(groupDocID)
        let userRef = db.collection("users").document(request.id)

        db.collection("grouprequest")
            .whereField("userID", isEqualTo: request.id)
            .whereField("groupID", isEqualTo: groupDocID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching join request: \(error.localizedDescription)")
                    return
                }

                guard let doc = snapshot?.documents.first else {
                    print("Join request not found for user: \(request.id)")
                    return
                }

                let requestRef = doc.reference
                let batch = db.batch()
                
                batch.updateData(["members": FieldValue.arrayUnion([request.id])], forDocument: groupRef)
                batch.updateData(["groups": FieldValue.arrayUnion([groupName])], forDocument: userRef)
                batch.deleteDocument(requestRef)

                batch.commit { error in
                    if let error = error {
                        print("Failed to accept join request: \(error.localizedDescription)")
                    } else {
                        print("User \(request.id) added to group")
                        fetchMembers()
                        fetchJoinRequests()
                    }
                }
            }
    }

    private func declineJoinRequest(_ request: SearchResultItem) {
        guard let groupDocID = groupDocID else { return }
        let db = Firestore.firestore()

        db.collection("grouprequest")
            .whereField("userID", isEqualTo: request.id)
            .whereField("groupID", isEqualTo: groupDocID)
            .getDocuments { snapshot, error in
                guard let doc = snapshot?.documents.first else { return }
                doc.reference.delete { err in
                    if err == nil {
                        fetchJoinRequests()
                    }
                }
            }
    }
    
    private func fetchJoinRequests() {
        guard let groupDocID = groupDocID, let currentUID = auth.user?.uid, currentUID == creatorID else { return }

        let db = Firestore.firestore()
        db.collection("grouprequest")
            .whereField("groupID", isEqualTo: groupDocID)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return }

                let userIDs = documents.compactMap { $0["userID"] as? String }.filter { !$0.isEmpty }

                // 🔐 Fix: Prevent crash if userIDs is empty
                guard !userIDs.isEmpty else {
                    DispatchQueue.main.async {
                        self.joinRequests = []
                    }
                    return
                }

                db.collection("users").whereField(FieldPath.documentID(), in: userIDs).getDocuments { userSnapshot, error in
                    guard let userDocs = userSnapshot?.documents else { return }

                    let fetchedRequests = userDocs.map { doc -> SearchResultItem in
                        let userData = doc.data()
                        return SearchResultItem(
                            id: doc.documentID,
                            title: userData["username"] as? String ?? "Unnamed",
                            subtitle: userData["email"] as? String,
                            type: .user
                        )
                    }

                    DispatchQueue.main.async {
                        self.joinRequests = fetchedRequests
                    }
                }
            }
    }
    
    private func joinGroup() {
        guard let groupDocID = groupDocID, let uid = auth.user?.uid else { return }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupDocID)
        let userRef = db.collection("users").document(uid)

        let batch = db.batch()
        batch.updateData(["members": FieldValue.arrayUnion([uid])], forDocument: groupRef)
        batch.updateData(["groups": FieldValue.arrayUnion([groupName])], forDocument: userRef)

        batch.commit { error in
            if let error = error {
                print("Error joining group: \(error.localizedDescription)")
            } else {
                isMember = true
                fetchMembers()
                checkMembership()
            }
        }
    }
    
    private func requestToJoinGroup() {
        guard let uid = auth.user?.uid, let groupDocID = groupDocID else { return }

        let db = Firestore.firestore()
        let request: [String: Any] = [
            "userID": uid,
            "groupID": groupDocID,
            "groupName": groupName,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("grouprequest").addDocument(data: request) { error in
            if let error = error {
                print("Failed to send join request: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    hasSentJoinRequest = true
                }
            }
        }
    }
    
    private func checkMembership() {
        if let uid = auth.user?.uid {
            isMember = members.contains(where: { $0.id == uid })
        }
    }

    private var canCurrentUserRemoveMembers: Bool {
        auth.user?.uid == creatorID
    }
    
    private func checkIfJoinRequestExists() {
        guard let uid = auth.user?.uid, let groupDocID = groupDocID else { return }

        let db = Firestore.firestore()
        db.collection("grouprequest")
            .whereField("userID", isEqualTo: uid)
            .whereField("groupID", isEqualTo: groupDocID)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    DispatchQueue.main.async {
                        hasSentJoinRequest = true
                    }
                }
            }
    }

    private func fetchGroupData() {
        let db = Firestore.firestore()
        db.collection("groups").whereField("name", isEqualTo: groupName).getDocuments { snapshot, error in
            guard let doc = snapshot?.documents.first else { return }

            let data = doc.data()

            DispatchQueue.main.async {
                groupDocID = doc.documentID
                creatorID = data["creator"] as? String
                isPrivateGroup = data["private"] as? Bool ?? false
                
                checkIfJoinRequestExists()
                fetchJoinRequests()
            }
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

                DispatchQueue.main.async {
                    self.members = fetchedMembers
                    checkMembership()
                    membershipChecked = true
                }
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
            VStack(spacing: 0) {
                Form {
                    if creatorID == auth.user?.uid {
                        Section(header: Text("Settings for \(groupName)")) {
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .tint(.green)
                            Toggle("Private Group", isOn: $isPrivate)
                                .tint(.green)
                                .onChange(of: isPrivate) {
                                    if let docID = groupDocID {
                                        Firestore.firestore().collection("groups").document(docID).updateData([
                                            "private": isPrivate
                                        ]) { error in
                                            if let error = error {
                                                print("Failed to update private setting: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                            Toggle("Share total screen time", isOn: $totalScreenTime)
                                .tint(.green)
                            Toggle("Share screen time on social media", isOn: $socialMediaTime)
                                .tint(.green)
                            Toggle("Share my digital habits score", isOn: $habitsScore)
                                .tint(.green)
                        }
                    } else {
                        Section(header: Text("Settings")) {
                            Text("Only the group creator can edit settings.")
                                .foregroundColor(.gray)
                        }
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

                // Group ID
                if let groupDocID = groupDocID {
                    Text("Group ID: \(groupDocID)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
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
            isPrivate = data["private"] as? Bool ?? false
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
