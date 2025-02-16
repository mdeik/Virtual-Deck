import SwiftUI

struct CardViewer: View {
    // EnvironmentObjects
    @EnvironmentObject var card: Card
    @EnvironmentObject var deck: Deck
    @EnvironmentObject var choice: Choice

    // State properties of card's photo. Used to keep track of if the card is in fullscreen mode and the zoom scale and offset of the card's image during that time
    @State private var isFullScreen = false // card image is double tapped
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero


    // State properties used for editing the card information
    @State private var isEditing = false // edit button is selected
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var newRarity = ""
    @State private var newType = ""

    var body: some View {
        if isFullScreen {
            // if the card image is double tapped
            GeometryReader { geometry in
                let imagePath = card.imageURL!.path
                if let image = UIImage(contentsOfFile: imagePath) {
                    // displays card image with zoom and drag controls
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(zoomScale * lastScale)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(CGSize(width: offset.width + dragOffset.width, height: offset.height + dragOffset.height))
                        .onTapGesture(count: 2) {
                        // exit full screen on double tap
                        isFullScreen = false
                        offset = .zero
                        lastScale = 1.0
                    }
                        .gesture(
                        // zoom controls
                        MagnificationGesture()
                            .onChanged { scale in
                            zoomScale = scale.magnitude
                        }
                            .onEnded { scale in
                            lastScale = zoomScale * lastScale
                            zoomScale = 1.0
                        }
                        // drag controls
                        .simultaneously(with: DragGesture()
                            .onChanged { value in
                            dragOffset.width = value.translation.width
                            dragOffset.height = value.translation.height
                        }
                            .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                            dragOffset = .zero
                        }
                        )
                    )
                } else {
                    // could not load image
                    Text("Failed to Load Image")
                }

            }
                .navigationBarHidden(true)
        } else if isEditing {
            // edit button is selectd
            ScrollView {
                TextField("Card Name", text: $newName, onCommit: cardWrite)
                    .textFieldStyle(.roundedBorder)
                    .font(.title)
                    .padding()
                    .onAppear {
                    newName = card.name
                }
                let imagePath = card.imageURL?.path ?? ""
                if let image = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Text("Failed to Load Image")

                }
                HStack {
                    if choice.cType {
                        TextField("Card Type", text: $newType, onCommit: cardWrite)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .onAppear {
                            newType = card.type
                        }
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if choice.cRar {
                        TextField("Card Rarity", text: $newRarity, onCommit: cardWrite)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                            .onAppear {
                            newRarity = card.rarity
                        }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                if choice.cDes {
                    TextField("Card Description", text: $newDescription, onCommit: cardWrite)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onAppear {
                        newDescription = card.description
                    }
                }
                Button(action: cardWrite) {
                    Text("Done")
                }
                Text("").padding(150)

            }
                .navigationBarHidden(true)
        } else {
            // Normal view
            ScrollView {
                let imagePath = card.imageURL?.path ?? ""
                if let image = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture(count: 2) {
                        isFullScreen = true
                    }
                        .contextMenu {
                        Button {
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: image)
                        } label: {
                            Label("Save Image", systemImage: "photo.artframe")
                        }
                    }
                } else {
                    Text("Failed to Load Image")
                }
                HStack {
                    // checks if card type, rarity, and/or description are enabled and displays them accordingly
                    if choice.cType {
                        Text(card.type).frame(maxWidth: .infinity, alignment: .leading).font(.title).bold()
                    }
                    if choice.cRar {
                        Text(card.rarity).frame(maxWidth: .infinity, alignment: .trailing).font(.title).bold()
                    }

                }
                if choice.cDes {
                    Text(card.description).font(.title3)
                }

            }
                .navigationBarTitle(card.name)
                .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                    }
                }
            }
        }

    }
    func cardWrite() {
        // updates current card with new information and saves it to deck
        card.name = (newName != "" ? newName : card.name)
        card.description = newDescription
        card.type = newType
        card.rarity = newRarity
        deck.save()
        isEditing = false
    }

    class ImageSaver: NSObject {
        // saves card image to photo album
        func writeToPhotoAlbum(image: UIImage) {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        }

        @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            print("Save finished!")
        }
    }
}

struct CardViewer_Previews: PreviewProvider {
    static var previews: some View {
        CardViewer()
    }
}
