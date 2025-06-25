//
//  Leaderboard.swift
//
//
//  Created by CJ Balmaceda on 6/20/25.
//

import SwiftUI

struct leaderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                    Text("Find friends & groups")
                        .font(.system(size: 15))
                    Spacer()
                }
                .padding()
                .background(Color(.white))
                .cornerRadius(7)
                .padding(.horizontal)
                
                // Suggested Friends
                VStack(alignment: .leading) {
                    HStack {
                        Text("My Groups")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    GroupCard(name: "new group", members: 1)
                    GroupCard(name: "group", members: 5)
                    
                }
                Spacer()
            }.cStyle1()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("Groups")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                }
        }
    }
}

struct GroupCard: View {
    var name: String
    var members: Int

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
                .overlay(Text("🙌"))
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.semibold)
                Text("\(members) member\(members == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    leaderView()
}
