//
//  ContentView.swift
//  BucketList
//
//  Created by Constantin Lisnic on 18/12/2024.
//

import CoreHaptics
import MapKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()

    @State private var engine: CHHapticEngine?

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

                                        LongPressGestureHapticFeedback()
                                    }
                                )
                        }
                    }
                }
                .onAppear(perform: prepareHaptics)
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
        } else {
            Button("Unlock") {
                viewModel.authenticate()
            }
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(.capsule)
        }
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print(
                "There was an error creating the engine: \(error.localizedDescription)"
            )
        }
    }

    func LongPressGestureHapticFeedback() {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        var events = [CHHapticEvent]()

        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(
            parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(
            parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(
            eventType: .hapticTransient, parameters: [intensity, sharpness],
            relativeTime: 0)
        events.append(event)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

#Preview {
    ContentView()
}
