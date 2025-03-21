import SwiftUI

struct MetadataView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Processing Image...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if let metadata = viewModel.metadata {
                    List {
                        let metadataSections = metadata.components(separatedBy: "\n\n")
                        ForEach(metadataSections, id: \.self) { section in
                            let lines = section.components(separatedBy: "\n")
                            if let title = lines.first {
                                Section(header: Text(title).font(.headline)) {
                                    ForEach(lines.dropFirst(), id: \.self) { line in
                                        Text(line)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    Text("No metadata available")
                        .padding()
                        .font(.headline)
                }
            }
        }
    }
}
