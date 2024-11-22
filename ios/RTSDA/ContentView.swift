//
//  ContentView.swift
//  RTSDA
//
//  Created by Benjamin Slingo on 11/16/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            NavigationView {
                BulletinView()
            }
            .tabItem {
                Label("Bulletin", systemImage: "newspaper.fill")
            }
            
            EventsView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
            
            SermonView()
                .tabItem {
                    Label("Messages", systemImage: "video.fill")
                }
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
