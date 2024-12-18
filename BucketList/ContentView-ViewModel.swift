//
//  ContentView-ViewModel.swift
//  BucketList
//
//  Created by Constantin Lisnic on 18/12/2024.
//

import Foundation
import MapKit
import LocalAuthentication
import CoreHaptics
import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
        private(set) var locations: [Location]
        var selectedPlace: Location?
        var isUnlocked = false
        
        var isHybridMode: Bool = UserDefaults.standard.bool(forKey: "isHybridMode") {
            didSet {
                UserDefaults.standard.set(isHybridMode, forKey: "isHybridMode")
            }
        }
        
        var isAuthenticationError: Bool = false
        
        var engine: CHHapticEngine?

        let savePath = URL.documentsDirectory.appending(path: "SavedPlaces")

        init() {
            do {
                let data = try Data(contentsOf: savePath)

                locations = try JSONDecoder().decode(
                    [Location].self, from: data)
            } catch {
                locations = []
            }
        }

        func addLocation(at point: CLLocationCoordinate2D) {
            let newLocation = Location(
                id: UUID(), name: "New Location", description: "",
                latitude: point.latitude,
                longitude: point.longitude)

            locations.append(newLocation)
            
            save()
        }

        func update(location: Location) {
            guard let selectedPlace else { return }

            if let index = locations.firstIndex(of: selectedPlace) {
                locations[index] = location
            }
            
            save()
        }

        func save() {
            do {
                let data = try JSONEncoder().encode(locations)
                try data.write(
                    to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save locations")
            }
        }
        
        func authenticate() {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Please autheticate yourself to unlock your places."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    success, authenticationError in
                    if success {
                        self.isUnlocked = true
                    } else {
                        self.isAuthenticationError = true
                    }
                }
            } else {
                // no biometrics
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
}
