//
//  CardView.swift
//  VirtualDeck
//
//  Created by Matthew Deik on 3/5/23.
//

import SwiftUI

struct CardView: View {

    @EnvironmentObject var deck: Deck
    @EnvironmentObject var choice: Choice
    @State private var showImagePicker: Bool = false
    @State private var image: UIImage?
    @State private var showNameInput: Bool = false
    @State private var cardName: String = ""
    @State private var source: String = "camera"
    @State private var selectMode: Bool = false
    @State private var selectedCards: Set<Card> = []
    @State private var searchText: String = ""
    @State private var subDecksOpt: Bool = true
    @State private var subDecks: [Deck] = []
    @State private var selectedDecks: Set<Deck> = []

    init() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            self._subDecks = State(initialValue: [])
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: [])
            let decks = try fileURLs.filter { $0.pathExtension == "json" }.compactMap { url -> Deck? in
                if let data = try? Data(contentsOf: url) {
                    let decoder = JSONDecoder()
                    return try decoder.decode(Deck.self, from: data)
                } else {
                    return nil
                }
            }
            self._subDecks = State(initialValue: decks)
        } catch {
            print(error.localizedDescription)
            self._subDecks = State(initialValue: [])
        }
    }

    private func loadSubDecks() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            subDecks = []
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: [])
            let decks = try fileURLs.filter { $0.pathExtension == "json" }.compactMap { url -> Deck? in
                if let data = try? Data(contentsOf: url) {
                    let decoder = JSONDecoder()
                    return try decoder.decode(Deck.self, from: data)
                } else {
                    return nil
                }
            }
            subDecks = decks
        } catch {
            print(error.localizedDescription)
            subDecks = []
        }
    }


    var filteredCards: [Card] {
        if searchText.isEmpty {
            if choice.cSort == 0 {
                return deck.deck.sorted(by: { $0.date < $1.date })
            } else {
                return deck.deck.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }

        } else {
            if choice.cSort == 0 {
                return deck.deck.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted(by: { $0.date < $1.date })
            } else {
                return deck.deck.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            }

        }
    }
    var sortedDecks: [Deck] {
        if choice.cSort == 0 {
            return subDecks.sorted(by: { $0.date < $1.date })
        } else {
            return subDecks.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        }

    }

    var body: some View {
        VStack {
            if deck.deck.isEmpty {
                Text("No cards in \(deck.name.components(separatedBy: ">").last ?? "deck")")
            } else {
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


                ForEach(sortedDecks.filter { subDeck in
                    guard subDeck.name.hasPrefix("\(deck.name)>"),
                        subDeck.name.filter({ $0 == ">" }).count == deck.name.filter({ $0 == ">" }).count + 1 else {
                        return false
                    }
                    return true
                }, id: \.self) { subDeck in
                    let subdeckName = subDeck.name.replacingOccurrences(of: "\(deck.name)>", with: "")
                    HStack {
                        if selectMode {
                            Button(action: {
                                if selectedDecks.contains(subDeck) {
                                    selectedDecks.remove(subDeck)
                                } else {
                                    selectedDecks.insert(subDeck)
                                }
                            }) {
                                if selectedDecks.contains(subDeck) {
                                    Image(systemName: "checkmark.circle.fill")
                                } else {
                                    Image(systemName: "circle")
                                }
                            }
                        }
                        if !selectMode {
                            NavigationLink(destination: CardView().environmentObject(subDeck)) {
                                Text(subdeckName).font(.title2)
                            }
                        } else {
                            Text(subdeckName)
                        }
                    }
                }

                List(filteredCards, id: \.self) { card in

                    HStack {
                        if selectMode {
                            Button(action: {
                                if selectedCards.contains(card) {
                                    selectedCards.remove(card)
                                } else {
                                    selectedCards.insert(card)
                                }
                            }) {
                                if selectedCards.contains(card) {
                                    Image(systemName: "checkmark.circle.fill")
                                } else {
                                    Image(systemName: "circle")
                                }
                            }
                        }
                        if !selectMode {
                            NavigationLink(destination: CardViewer()
                                .environmentObject(card)
                                .environmentObject(deck)
                                .environmentObject(choice)
                            ) {
                                if let imagePath = card.imageURL?.path,
                                    let image = UIImage(contentsOfFile: imagePath) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else {
                                    Text("Failed to Load Image")
                                }

                                Text(card.name)

                            }
                        } else {
                            if let imagePath = card.imageURL?.path,
                                let image = UIImage(contentsOfFile: imagePath) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            } else {
                                Text("Failed to Load Image")
                            }

                            Text(card.name)
                        }
                    }
                }
            }
        }
            .onAppear {
            loadSubDecks()
        }
            .navigationBarTitle(Text(deck.name.components(separatedBy: ">").last ?? ""))
            .toolbar {

            if selectMode {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Spacer()
                    Button(action: {
                        for card in selectedCards {
                            if let imageURL = card.imageURL {
                                try? FileManager.default.removeItem(at: imageURL)
                            }
                            deck.removeCard(card)
                        }
                        let fileManager = FileManager.default
                        for selDeck in selectedDecks {
                            if let index = subDecks.firstIndex(of: selDeck) {
                                subDecks.remove(at: index)

                                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let jsonFiles = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

                                for jsonFile in jsonFiles ?? [] {
                                    if jsonFile.lastPathComponent.hasPrefix(selDeck.name) {
                                        try? fileManager.removeItem(at: jsonFile)
                                    }
                                }
                            } }
                        selectMode.toggle()
                        selectedCards = []
                        selectedDecks = []
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                        .disabled(selectedCards.isEmpty && selectedDecks.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // creates a sub deck from selected cards, if any
                        self.addDeck()
                        selectMode.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // toggles select mode
                        selectMode.toggle()
                        selectedCards = []
                        selectedDecks = []
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                    }
                }

            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // create a card from photo library
                        source = "photos"
                        self.showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // create a card from camera
                        source = "camera"
                        self.showImagePicker = true
                    }) {
                        Image(systemName: "camera")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // toggle select mode
                        selectMode.toggle()
                        selectedCards = []
                        selectedDecks = []
                    }) {
                        Image(systemName: "checkmark.circle")
                    }
                }
            }

        }
            .fullScreenCover(isPresented: $showImagePicker, onDismiss: {
            saveImage()
            self.showNameInput = true
        }) {
            ImagePicker(image: self.$image, source: $source)
        }
            .sheet(isPresented: $showNameInput, content: {
            VStack {
                TextField("Enter card name", text: $cardName)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Save") {
                    // save created card to deck
                    guard let image = image else {
                        return
                    }
                    let toAdd = Card()
                    toAdd.saveImage(image)
                    toAdd.name = cardName
                    deck.addCard(toAdd)
                    self.image = nil
                    self.cardName = ""
                    self.showNameInput = false
                    // encode and save the deck to UserDefaults
                    if let encoded = try? JSONEncoder().encode(deck) {
                        UserDefaults.standard.set(encoded, forKey: "deck") // remove?
                    }
                }
                    .padding()
                    .disabled(cardName.isEmpty)

                Spacer()
            }
        })


    }

    func saveImage() {
        guard let image = image else {
            return
        }
        self.image = image
    }
    func addDeck() {
        let alertController = UIAlertController(title: "New Deck", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Deck name"
        }
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let deckName = alertController.textFields?.first?.text {
                if self.subDecks.contains(where: { $0.name == deckName }) {
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
                    newDeck.name = "\(deck.name)>\(deckName)"
                    print(selectedCards)
                    for card in selectedCards {
                        newDeck.addCard(card)
                    }
                    subDecks.append(newDeck)
                    selectedCards = []
                    let encoder = JSONEncoder()
                    if let encoded = try? encoder.encode(self.subDecks) {
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
}
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var source: String
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if source == "photos" {
            picker.sourceType = .photoLibrary
        } else {
            picker.sourceType = .camera
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
