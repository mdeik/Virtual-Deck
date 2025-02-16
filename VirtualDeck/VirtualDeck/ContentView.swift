//
//  ContentView.swift
//  VirtualDeck
//
//  Created by Matthew Deik on 3/4/23.
//

import SwiftUI
/*
 immediate to do:
 -Create Deck Class
 -Create Card Class
 -Update Decks
 -Figure out import pictures / using camera
 
 
 ## Project Timeline

 ***Milestone 1:***
 * Add and delete a deck of cards
 * The ability to use camera or camera roll


 ***Milestone 2:***
 * Creation of subdecks
 * Editing existing decks
 * Improve user interface

 ***Milestone 3:***
 * Zoom function for individual cards
 * Search functionality

 Begin working on stretch goals
 
 ## Stretch Goals
 * An ability to lock a deck to prevent acidental changes
 * A way to export/import a deck
 * The option to categorize cards by game, rarity, type, and other customizable fields
 * A description field for decks
 * The option to view cards and decks in a grid or list view
 * Improve search function by allowing to search for specific cards

 **Final Submission:**
 * All minimal goals completed
 * A couple stretch goals included
 
 */
public enum Sort: Int {
    case Date
    case Name
}

class Choice: ObservableObject {
    private let dSortKey = "dSort"
    private let cSortKey = "cSort"
    private let cDesKey = "cDes"
    private let cRarKey = "cRar"
    private let cTypeKey = "cType"
    private let disModeKey = "disMode"

    @Published var dSort: Int {
        didSet {
            UserDefaults.standard.set(dSort, forKey: dSortKey)
        }
    }
    @Published var cSort: Int {
        didSet {
            UserDefaults.standard.set(cSort, forKey: cSortKey)
        }
    }
    @Published var cDes: Bool {
        didSet {
            UserDefaults.standard.set(cDes, forKey: cDesKey)
        }
    }
    @Published var cRar: Bool {
        didSet {
            UserDefaults.standard.set(cRar, forKey: cRarKey)
        }
    }
    @Published var cType: Bool {
        didSet {
            UserDefaults.standard.set(cType, forKey: cTypeKey)
        }
    }
    @Published var disMode: Int {
        didSet {
            UserDefaults.standard.set(disMode, forKey: disModeKey)
        }
    }
    init() {
        self.dSort = UserDefaults.standard.integer(forKey: dSortKey)
        self.cSort = UserDefaults.standard.integer(forKey: cSortKey)
        self.cDes = UserDefaults.standard.bool(forKey: cDesKey)
        self.cRar = UserDefaults.standard.bool(forKey: cRarKey)
        self.cType = UserDefaults.standard.bool(forKey: cTypeKey)
        self.disMode = UserDefaults.standard.integer(forKey: disModeKey)
    }
}


struct ContentView: View {
    @ObservedObject var choice: Choice = Choice()

    var body: some View {
        HStack {
            TabView {
                Decks().tabItem {
                    Label("Decks", systemImage: "folder")
                }
                Settings().tabItem {
                    Label("Settings", systemImage: "gear")
                }
            }.environmentObject(choice)
                .onAppear {
                switch choice.disMode {
                case 1:
                    // force light mode
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let window = windowScene.windows.first {
                        window.overrideUserInterfaceStyle = .light
                    }
                case 2:
                    // force dark mode
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let window = windowScene.windows.first {
                        window.overrideUserInterfaceStyle = .dark
                    }
                default:
                    // restore original mode
                    break
                }
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
