//
//  ContentView.swift
//  BucketList
//
//  Created by Constantin Lisnic on 18/12/2024.
//

import MapKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()

    let startPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56, longitude: -3),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )

    var body: some View {
        if viewModel.isUnlocked {
            MapReader { proxy in
                Map(initialPosition: startPosition) {
                    ForEach(viewModel.locations) { location in
                        Annotation(
                            location.name,
                            coordinate: location.coordinate
                        ) {
                            Image(systemName: "star.circle")
                                .resizable()
                                .foregroundStyle(.red)
                                .frame(width: 44, height: 44)
                                .background(.white)
                                .clipShape(.circle)
                                .simultaneousGesture(
                                    LongPressGesture().onEnded { _ in
                                        viewModel.selectedPlace = location

                                        viewModel.LongPressGestureHapticFeedback()
                                    }
                                )
                        }
                    }
                }
                .mapStyle(viewModel.isHybridMode ? .hybrid : .standard)
                .onAppear(perform: viewModel.prepareHaptics)
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        viewModel.addLocation(at: coordinate)
                    }
                }
                .sheet(item: $viewModel.selectedPlace) { place in
                    EditView(location: place) {
                        viewModel.update(location: $0)
                    }
                }
            }
            Toggle("Hybrid mode", isOn: $viewModel.isHybridMode)
                .padding(.horizontal)

        } else {
            Button("Unlock") {
                viewModel.authenticate()
            }
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(.capsule)
            .alert(
                "Authenticatin error",
                isPresented: $viewModel.isAuthenticationError
            ) {
                Button("OK") {}
            } message: {
                Text("Try again")
            }
        }
    }
}

#Preview {
    ContentView()
}
