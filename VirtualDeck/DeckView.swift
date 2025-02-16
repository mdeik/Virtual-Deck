//  Decks.swift
//  VirtualDeck
//
//  Created by Matthew Deik on 3/4/23.
//

import SwiftUI

struct Decks: View {

    @State private var decks: [Deck]
    @State private var selectMode: Bool = false
    @State private var selectedDecks: Set<Deck> = []
    @State private var searchText: String = ""
    @EnvironmentObject var choice: Choice


    init() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            self._decks = State(initialValue: [])
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: [])
            var decks = [Deck]()
            var imageFileNames = [String]()
            var fileNames = Set<String>()
            
            // Create a list of JSON file names and a list of image file names
            for url in fileURLs {
                if url.pathExtension == "json", let data = try? Data(contentsOf: url) {
                    let decoder = JSONDecoder()
                    if let deck = try? decoder.decode(Deck.self, from: data) {
                        decks.append(deck)
                        imageFileNames.append(contentsOf: deck.imageFilenames())
                        print(imageFileNames)
                        print(deck.imageFilenames())
                    }
                } else {
                    fileNames.insert(url.lastPathComponent)
                }
            }
            
            // Delete image files that are not associated with any JSON files
            let unusedFileNames = fileNames.subtracting(Set(imageFileNames))
            
            for fileName in unusedFileNames {
                let fileURL = documentDirectory.appendingPathComponent(fileName)
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            self._decks = State(initialValue: decks)
        } catch {
            print(error.localizedDescription)
            self._decks = State(initialValue: [])
        }
    }




    var filteredDecks: [Deck] {
        if searchText.isEmpty {
            if choice.dSort == 0 {
                return decks.filter { !$0.name.contains(">") }.sorted(by: { $0.date < $1.date })
            } else {
                return decks.filter { !$0.name.contains(">") }.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }

        } else {
            if choice.dSort == 0 {
                return decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted(by: { $0.date < $1.date })
            } else {
                return decks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }

        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    SearchBar(text: $searchText)
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            windowScene.windows.first(where: { $0.isKeyWindow })?.endEditing(true)
                        }
                    }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }.foregroundColor(.blue)
                }
                List {
                    ForEach(filteredDecks, id: \.self) { deck in
                        let deckName = deck.name.components(separatedBy: ">").last ?? ""
                        HStack {
                            if selectMode {
                                Button(action: {
                                    if selectedDecks.contains(deck) {
                                        selectedDecks.remove(deck)
                                    } else {
                                        selectedDecks.insert(deck)
                                    }
                                }) {
                                    if selectedDecks.contains(deck) {
                                        Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle").foregroundColor(.blue)
                                    }
                                }
                            }
                            if !selectMode {
                                NavigationLink(destination: CardView().environmentObject(deck).environmentObject(choice)) {
                                    Text(deckName)
                                    if deck.lock {
                                        Image(systemName: "lock.fill").foregroundColor(.yellow)
                                    }
                                }
                            } else {
                                Text(deckName)
                                if deck.lock {
                                    Image(systemName: "lock.fill").foregroundColor(.yellow)
                                }
                            }
                        }
                    }

                }
                    .navigationBarTitle(Text("Decks"))
                    .toolbar {
                    if selectMode {

                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                // delete selected decks
                                let alert = UIAlertController(title: "Delete Decks", message: "Are you sure you want to delete these decks?", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                                    for deck in selectedDecks {
                                        if !deck.lock {
                                            deleteDeck(deck)
                                        }
                                        selectedDecks = []
                                    }
                                }))
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                    let rootViewController = windowScene.windows.first?.rootViewController else {
                                    return
                                }
                                rootViewController.present(alert, animated: true)
                                selectMode.toggle()
                                
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        } /*
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // export selected decks
                                // not yet implemented
                                selectMode.toggle()
                                selectedDecks = []
                            }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        } */
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // locks a deck to prevent deletion
                                for selDeck in selectedDecks {
                                    selDeck.lock.toggle()
                                    selDeck.save()
                                }
                                selectMode.toggle()
                                selectedDecks = []

                            }) {
                                Image(systemName: "lock")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // toggles select mode
                                selectMode.toggle()
                                selectedDecks = []
                            }) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                            }
                        }
                    } else { /*
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // import deck(s)
                                // not yet implemented
                                let importAlert = UIAlertController(title: "Import Deck", message: "Would you like to import a deck?", preferredStyle: .alert)

                                importAlert.addAction(UIAlertAction(title: "Import", style: .default) { _ in
                                    // import from a .json file or something
                                })

                                importAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                    let rootViewController = windowScene.windows.first?.rootViewController else {
                                    return
                                }

                                rootViewController.present(importAlert, animated: true)
                            }) {
                                Image(systemName: "square.and.arrow.down")
                            }
                        } */
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // create new deck
                                self.addDeck()
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // toggle select mode
                                selectMode.toggle()
                                selectedDecks = []
                            }) {
                                Image(systemName: "checkmark.circle").foregroundColor(.blue)
                            }
                        }
                    }

                }

            }

        }

    }


    func addDeck() {
        let alertController = UIAlertController(title: "New Deck", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Deck name"
        }
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let deckName = alertController.textFields?.first?.text {
                if self.decks.contains(where: { $0.name == deckName }) {
                    // deck name already exists, show an error message
                    let errorAlert = UIAlertController(title: "Error", message: "Deck name already exists", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    errorAlert.addAction(okAction)
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        let rootViewController = windowScene.windows.first?.rootViewController else {
                        return
                    }
                    rootViewController.present(errorAlert, animated: true)
                } else {
                    // deck name is unique, create a new deck
                    let newDeck = Deck()
                    newDeck.name = deckName
                    self.decks.append(newDeck)
                    let encoder = JSONEncoder()
                    if let encoded = try? encoder.encode(self.decks) {
                        UserDefaults.standard.setValue(encoded, forKey: "decks")
                    }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(createAction)
        alertController.addAction(cancelAction)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        rootViewController.present(alertController, animated: true)
    }



    func deleteDeck(_ deck: Deck) {
        if let index = decks.firstIndex(of: deck) {
            decks.remove(at: index)

            // remove JSON file
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let jsonFiles = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

            for jsonFile in jsonFiles ?? [] {
                if jsonFile.lastPathComponent.hasPrefix(deck.name) {
                    try? fileManager.removeItem(at: jsonFile)
                }
            }

            // remove card files
            for card in deck.deck {
                if let imageURL = card.imageURL {
                    try? FileManager.default.removeItem(at: imageURL)
                }
            }
        }
    }



    func deleteDeck(at offsets: IndexSet) {
        for index in offsets {
            let deck = decks[index]
            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { continue }

            do {
                // remove JSON file
                let jsonFiles = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                for jsonFile in jsonFiles {
                    if jsonFile.lastPathComponent.hasPrefix(deck.name) {
                        try FileManager.default.removeItem(at: jsonFile)
                    }
                }

                // remove card files
                for card in deck.deck {
                    if let imageURL = card.imageURL {
                        try? FileManager.default.removeItem(at: imageURL)
                    }
                }

                deck.emptyDeck()
                decks.remove(at: index)
            } catch {
                print("Error removing file: \(error)")
            }
        }
    }

}


struct SearchBar: UIViewRepresentable {

    @Binding var text: String

    class Coordinator: NSObject, UISearchBarDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }

    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }
}
