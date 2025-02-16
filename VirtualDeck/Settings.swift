//
//  Settings.swift
//  VirtualDeck
//
//  Created by Matthew Deik on 3/4/23.
//

import SwiftUI

struct Settings: View {

    let options = ["System Default", "Light Mode", "Dark Mode"]
    //let viewStyle = ["List View", "Grid View"]
    let sortOpts = ["Date", "Name"]
    @State private var selectView = 0
    @EnvironmentObject var choice: Choice
    @State private var sysDefault = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Settings"), footer: sysDefault ? Text("To restore System Default, app must be relaunched") : Text("")) {
                    Picker(selection: $choice.disMode, label: Text("Toggle")) {
                        ForEach(0..<3) { index in
                            Text(self.options[index]).tag(index)

                        }
                    }
                   /* Picker(selection: $selectView, label: Text("Toggle")) {
                        ForEach(0..<2) { index in
                            Text(self.viewStyle[index]).tag(index)
                        }
                    }*/
                }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(3)
                    .onChange(of: choice.disMode) { _ in

                    switch choice.disMode {
                    case 1:
                        sysDefault = false
                        // Force Light Mode
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                            let window = windowScene.windows.first {
                            window.overrideUserInterfaceStyle = .light
                        }
                    case 2:
                        sysDefault = false
                        // Force Dark Mode
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                            let window = windowScene.windows.first {
                            window.overrideUserInterfaceStyle = .dark
                        }
                    default:
                        sysDefault = true
                        break
                    }
                }
                Section(header: Text("Sorting")) {
                    HStack {
                        Text("Decks:")
                        Picker(selection: $choice.dSort, label: Text("Toggle")) {
                            ForEach(0..<2) { index in
                                Text(self.sortOpts[index]).tag(index)
                            }
                        }
                    }

                    HStack {
                        Text("Cards:")
                        Picker(selection: $choice.cSort, label: Text("Toggle")) {
                            ForEach(0..<2) { index in
                                Text(self.sortOpts[index]).tag(index)
                            }
                        }
                    }
                }
                    .pickerStyle(SegmentedPickerStyle())

                Section(header: Text("Card Fields")) {
                    Toggle("Type", isOn: $choice.cType)
                    Toggle("Rarity", isOn: $choice.cRar)
                    Toggle("Description", isOn: $choice.cDes)
                }
            }
                .navigationBarTitle(Text("Settings"))
        }

    }
}




