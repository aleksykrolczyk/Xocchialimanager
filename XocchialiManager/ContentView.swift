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

        if btcontroller.touchpads != nil {
            HStack {
                TouchpadVisualizer(text: "Play", isActive: btcontroller.touchpads!.play < 250)
                TouchpadVisualizer(text: "Set", isActive: btcontroller.touchpads!.set < 250)
                TouchpadVisualizer(text: "Vol-", isActive: btcontroller.touchpads!.volumeDown < 250)
                TouchpadVisualizer(text: "Vol+", isActive: btcontroller.touchpads!.volumeUp < 250)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct TouchpadVisualizer: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text)
            .padding()
            .overlay {
                Circle()
                    .stroke(isActive ? .green : .red, lineWidth: 4)
            }
    }
}
