//
//  Model.swift
//  VirtualDeck
//
//  Created by Matthew Deik on 3/4/23.
//
import Foundation
import SwiftUI


public class Deck: ObservableObject, Equatable, Hashable, Codable {
    @Published var deck: [Card]
    @Published var name: String
    @Published var lock: Bool
    @Published var date: Date
    init() {
        self.deck = []
        self.name = ""
        self.lock = false
        self.date = Date()
    }

    init(name: String) {
        self.deck = []
        self.name = name
        self.lock = false
        self.date = Date()

        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentDirectory.appendingPathComponent(name).appendingPathExtension("json")
        do {
            let data = try Data(contentsOf: fileURL)
            let savedDeck = try JSONDecoder().decode(Deck.self, from: data)
            self.deck = savedDeck.deck
            self.name = savedDeck.name
            self.lock = savedDeck.lock
            self.date = savedDeck.date
        } catch {
            self.deck = []
        }
    }

    func addCard(_ card: Card) {
        deck.append(card)
        save()
    }

    func removeCard(_ card: Card) {
        deck.removeAll(where: { $0 == card })
        save()
    }
    func removeCard(at offsets: IndexSet) {
        deck.remove(atOffsets: offsets)
        save()
    }


    func emptyDeck() {
        deck.forEach { card in
            card.deleteImage()
        }
        deck.removeAll()
    }

    func cardExists(_ card: Card) -> Bool {
        deck.contains(card)
    }

    public static func == (lhs: Deck, rhs: Deck) -> Bool {
        return lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)

    }

    enum CodingKeys: String, CodingKey {
        case deck
        case name
        case lock
        case date
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deck = try container.decode([Card].self, forKey: .deck)
        name = try container.decode(String.self, forKey: .name)
        lock = try container.decode(Bool.self, forKey: .lock)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deck, forKey: .deck)
        try container.encode(name, forKey: .name)
        try container.encode(lock, forKey: .lock)
        try container.encode(date, forKey: .date)
    }

    public func save() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentDirectory.appendingPathComponent(name).appendingPathExtension("json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(self)
            try data.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func imageFilenames() -> [String] {
        var filenames = [String]()
        for card in deck {
                filenames.append(card.id.uuidString)
        }
        return filenames
    }

}




public class Card: ObservableObject, Equatable, Identifiable, Codable, Hashable {
    @Published var name: String
    @Published var imageFilename: String?
    @Published var imageURL: URL?
    @Published var description: String
    @Published var date: Date
    @Published var type: String
    @Published var rarity: String
    public let id: UUID

    init() {
        name = ""
        imageFilename = nil
        description = ""
        id = UUID()
        imageURL = nil
        date = Date()
        type = ""
        rarity = ""
    }

    public static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case imageFilename
        case description
        case id
        case imageURL
        case date
        case type
        case rarity
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        description = try container.decode(String.self, forKey: .description)
        id = try container.decode(UUID.self, forKey: .id)
        imageURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(id.uuidString)
        date = try container.decode(Date.self, forKey: .date)
        type = try container.decode(String.self, forKey: .type)
        rarity = try container.decode(String.self, forKey: .rarity)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(imageFilename, forKey: .imageFilename)
        try container.encode(description, forKey: .description)
        try container.encode(id, forKey: .id)
        try container.encode(imageURL, forKey: .imageURL)
        try container.encode(date, forKey: .date)
        try container.encode(type, forKey: .type)
        try container.encode(rarity, forKey: .rarity)
    }

    func saveImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = documentsDirectory.appendingPathComponent(id.uuidString)
            try data.write(to: fileURL)
            imageURL = fileURL
        } catch {
            print(error)
        }
    }
    func deleteImage() {
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = documentsDirectory.appendingPathComponent(id.uuidString)
            try FileManager.default.removeItem(at: fileURL)
            self.imageURL = nil
        } catch {
            print(error)
        }
    }


}
