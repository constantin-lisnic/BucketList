//
//  EditView.swift
//  BucketList
//
//  Created by Constantin Lisnic on 18/12/2024.
//

import SwiftUI

struct EditView: View {
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: ViewModel
    var onSave: (Location) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Place name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                }

                Section("Nearby...") {
                    switch viewModel.loadingState {
                    case .loaded:
                        ForEach(viewModel.pages, id: \.pageid) { page in
                            Text(page.title)
                                .font(.headline) + Text(": ")
                                + Text("PageDescription here")
                                .italic()

                        }

                    case .failed:
                        Text("Please try again later.")

                    case .loading:
                        Text("Loading...")
                    }

                }
            }
            .navigationTitle("Place details")
            .toolbar {
                Button("Save") {
                    let newLocation = viewModel.getNewLocation()

                    onSave(newLocation)
                    dismiss()
                }
            }
            .task {
                await viewModel.fetchNearbyPages()
            }
        }
    }

    init(location: Location, onSave: @escaping (Location) -> Void) {
        self.onSave = onSave

        _viewModel = State(initialValue: ViewModel(location: location))
    }
}

#Preview {
    EditView(location: .example, onSave: { _ in })
}
