//
//  ContentView.swift
//  uv_spec_app
//
//  Created by Ali Zia on 9/22/24.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingCamera = false
    @State private var inputImage: UIImage?

    var body: some View {
        VStack {
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
                    .padding()
            }

            Button(action: {
                isShowingCamera = true
            }) {
                Text("Take a Photo")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .sheet(isPresented: $isShowingCamera) {
                ImagePicker(image: $inputImage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

