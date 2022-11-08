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
            HStack() {
                Text("Device status: ")
                Spacer()
                Text(btcontroller.peripheral == nil ? "Disconnected" : "Connected")
                    .foregroundColor(btcontroller.peripheral == nil ? .red : .green)
            }
            HStack {
                Text("Play button status (value: \(btcontroller.playValue != nil ? String(btcontroller.playValue!) : "MIA")) ")
                Spacer()
                Text(btcontroller.playValue != nil && btcontroller.playValue! < 250 ? "Touched" : "Not touched")
                    .foregroundColor(btcontroller.playValue != nil && btcontroller.playValue! < 250 ? .green : .red)
            }
        }
        .padding()
        Spacer()
        
        HStack {
            Button("Toggle LED On") {btcontroller.toggleLEDOn() }
            Spacer()
            Button("Toggle LED Off") {btcontroller.toggleLEDOff() }
        }
        .padding()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
