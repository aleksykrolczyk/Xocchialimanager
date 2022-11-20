//
//  ContentView.swift
//  XocchialiManager
//
//  Created by Aleksy Krolczyk on 05/11/2022.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var btcontroller = BTController()

    var body: some View {
        Text("Xocchiali Manager")
            .font(.largeTitle)
            .rainbowAnimation()
            .padding()

        Spacer()
        VStack {
            HStack {
                Text("Device status: ")
                Spacer()
                Text(btcontroller.peripheral == nil ? "Disconnected" : "Connected")
                    .foregroundColor(btcontroller.peripheral == nil ? .red : .green)
            }
            .padding()
        }
        .padding()
        Spacer()

        HStack {
            TouchpadVisualizer(text: "Play", state: btcontroller.touchpads.play)
            TouchpadVisualizer(text: "Set", state: btcontroller.touchpads.set)
            TouchpadVisualizer(text: "Vol-", state: btcontroller.touchpads.volumeDown)
            TouchpadVisualizer(text: "Vol+", state: btcontroller.touchpads.volumeUp)
        }
        .padding()

        Spacer()
        HStack {
            Button("Toggle LED On") { btcontroller.toggleLEDOn() }
                .padding()
            Button("Toggle LED Off") { btcontroller.toggleLEDOff() }
                .padding()
        }
        .padding()

        
        

        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

let TOUCHPAD_VISUALIZER_COLORS: [Touchpads.State: Color] = [
    .idle: .red,
    .shortPress: .green,
    .longPress: .blue
]

struct TouchpadVisualizer: View {
    let text: String
    let state: Touchpads.State

    
    var body: some View {
        Text(text)
            .padding()
            .overlay {
                Circle()
                    .stroke(TOUCHPAD_VISUALIZER_COLORS[state] ?? .red, lineWidth: 4)
            }
    }
}
