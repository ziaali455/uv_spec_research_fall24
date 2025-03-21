//
//  RGBValuesView.swift
//  uvsn
//
//  Created by Ali Zia on 3/14/25.
//

import SwiftUI
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI

struct RGBValuesView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Processing Image...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if let image = viewModel.inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    Text("Select Photo")
                }
                .padding()
                
                if let rgb = viewModel.rgbValues {
                    Text("RGB Values: [\(rgb.r), \(rgb.g), \(rgb.b)]")
                }
            }
        }
    }
}
