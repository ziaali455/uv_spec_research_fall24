//
//  MainView.swift
//  uvsn
//
//  Created by Ali Zia on 10/11/24.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI
struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Chromaticity Tab
                ChromaticityView(viewModel: viewModel)
                    .tabItem {
                        Label("Chromaticity", systemImage: "circle.grid.3x3")
                    }
                    .tag(0)

                // RGB Values Tab
                RGBValuesView(viewModel: viewModel)
                    .tabItem {
                        Label("RGB Values", systemImage: "paintpalette")
                    }
                    .tag(1)

                // Metadata Tab
                MetadataView(viewModel: viewModel)
                    .tabItem {
                        Label("Metadata", systemImage: "info.circle")
                    }
                    .tag(2)
            }
            .navigationTitle("uvsn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.exportData) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(!viewModel.isExportEnabled)
                }
            }
        }
    }
}


/**
 
 Here's what's happening:

 RAW Data Loading: The PhotosPicker successfully loads the RAW image data.

 CGImage Creation: A CGImage is created from the RAW data. At this point, some initial processing is happening to convert the RAW data into a displayable image. However, this processing is basic and likely not optimized for accurate colorimetric analysis.

 UIImage Creation: A UIImage is created from the CGImage.

 Standard Processing: From this point forward, the UIImage is treated like any other image. The calculateChromaticity function, extractRGB, and other functions operate on the already "processed" UIImage.
 
 */
