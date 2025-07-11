//
//  DetailedSearch.swift
//  Bettr
//
//  Created by Finbar McCarron on 7/10/25.
//

import SwiftUI

struct DetailedSearch: View {
    let query: String
    let excludingGroups: [String]
    let dismiss: () -> Void
    @ObservedObject var auth: fireAuth

    @State private var selectedTab = "Accounts"
    @StateObject private var searchVM = SearchViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Picker("Search Type", selection: $selectedTab) {
                    Text("Accounts").tag("Accounts")
                    Text("Groups").tag("Groups")
                }
                .pickerStyle(.segmented)
                .padding()

                List {
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
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                searchVM.currentUserID = auth.user?.uid
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
            // Groups — You can extend this to add to user's groups if needed
            print("Selected group: \(item.title)")
        }
    }
}
