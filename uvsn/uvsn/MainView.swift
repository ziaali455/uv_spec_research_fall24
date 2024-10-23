//
//  MainView.swift
//  uvsn
//
//  Created by Ali Zia on 10/11/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
            ResultsView()
                .tabItem{
                    Image(systemName: "tray.full")
                    Text("Results")
                }

        }
    }
}
#Preview {
    MainView()
}

