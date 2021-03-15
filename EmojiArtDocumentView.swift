//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Vicente Montoya on 8/28/20.
//  Copyright © 2020 Vicente Montoya. All rights reserved.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPalette: String = ""
    
    init(document: EmojiArtDocument){
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }
    
    var body: some View {
        VStack {
            HStack{
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: self.defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString) }
                        }
                    }
                }
                
                Button(action: {
                    for emoji in self.document.emojis{
                        if self.selectedEmojis.contains(matching: emoji){
                            self.document.removeEmoji(emoji)
                        }
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                }.alignmentGuide(.trailing, computeValue:{d in d[.trailing]})
            }.padding(.horizontal)

            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: self.document.backgroundImage)
                            .scaleEffect(self.zoomScale)
                            .offset(self.panOffset)
                    )
                        .gesture(self.doubleTapToZoom(in: geometry.size))
                    
                    if self.isLoading{
                        Image(systemName: "hourglass").imageScale(.large).spinning()
                    }else{
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                .opacity(self.selectedEmojis.contains(matching: emoji) ? 0.5 : 1)
                                .font(animatableWithSize: emoji.fontSize * self.zoomScale * self.emojiZoomFactor(for: emoji) )
                                .position(self.position(for: emoji, in: geometry.size))
                                .gesture(self.selectGesture(for: emoji))
                                .gesture(self.emojiPanGesture())
                            
                        }
                    }
                    
                }
                .clipped()
                .gesture(self.panGesture())
                .gesture(self.backgroundSelectGesture().exclusively(before: self.zoomGesture()))
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(self.document.$backgroundImage){ image in
                    self.zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image","public.text"], isTargeted: nil) { providers, location in
                    // SwiftUI bug (as of 13.4)? the location is supposed to be in our coordinate system
                    // however, the y coordinate appears to be in the global coordinate system
                    var location = CGPoint(x: location.x, y: geometry.convert(location, from: .global).y)
                    location = CGPoint(x: location.x - geometry.size.width/2, y: location.y - geometry.size.height/2)
                    location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                    location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                    return self.drop(providers: providers, at: location)
                }
                .navigationBarItems(trailing:
                    Button(
                        action: {
                            if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                                self.confirmBackgroundPaste = true
                            } else {
                                self.explainBackgroundPaste = true
                            }
                        },
                        label: {
                            Image(systemName: "doc.on.clipboard").imageScale(.large)
                                .alert(isPresented: self.$explainBackgroundPaste){
                                    Alert (
                                        title: Text("Paste Background"),
                                        message: Text("Copy the URL of an image to the clipboard and touch this button to make it the background of your document"),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                        }
                    )
                )
            }
        .zIndex(-1)
        }.alert(isPresented: self.$confirmBackgroundPaste){
                 Alert (
                    title: Text("Paste Background"),
                    message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?"),
                    primaryButton: .default(Text("OK")){
                        self.document.backgroundURL = UIPasteboard.general.url
                    },
                    secondaryButton: .cancel()
                )
        }
    }
    
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false
    
    
    //MARK: - Gesture: Select
    
    @State private var selectedEmojis: Set<EmojiArt.Emoji> = []
    
    private func selectGesture(for emoji: EmojiArt.Emoji) -> some Gesture{
        TapGesture(count: 1)
            .onEnded{
                if self.selectedEmojis.contains(matching: emoji){
                    self.selectedEmojis.remove(emoji)
                }else{
                    self.selectedEmojis.insert(emoji)
                }
        }
    }
    
    //MARK: - Gesture: Emoji Zoom
    
    @GestureState private var gestureZoomScaleEmoji: CGFloat = 1.0
    
    private func emojiZoomFactor(for emoji: EmojiArt.Emoji) -> CGFloat{
        if selectedEmojis.contains(matching: emoji) {
            return gestureZoomScaleEmoji
        } else {
            return 1.0
        }
    }
    
    //MARK: - Gesture: Emoji Panning
    
    @GestureState private var gestureEmojiPanOffset: CGSize = .zero
    
    private func emojiPanOffset(for emoji: EmojiArt.Emoji) -> CGSize {
        if selectedEmojis.contains(matching: emoji) {
            return (gestureEmojiPanOffset) * zoomScale
        } else {
            return .zero
        }
    }
    
    private func emojiPanGesture() -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            for emoji in self.selectedEmojis {
                self.document.moveEmoji(emoji, by: finalDragGestureValue.translation / self.zoomScale)
            }
        }
    }
    
    var isLoading: Bool{
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    //MARK: - Gesture: Background Select Gesture
    
    private func backgroundSelectGesture() -> some Gesture{
        TapGesture(count: 1)
            .onEnded(){
                self.selectedEmojis = []
        }
    }
    
    //MARK: - Gesture: Background Zoom
    
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        self.document.steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating(self.selectedEmojis.isEmpty ? $gestureZoomScale : $gestureZoomScaleEmoji )
            { latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
        }
        .onEnded { finalGestureScale in
            if self.selectedEmojis.isEmpty {
                self.document.steadyStateZoomScale *= finalGestureScale
            } else{
                for emoji in self.selectedEmojis {
                    self.document.scaleEmoji(emoji, by: finalGestureScale)
                }
            }
            
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    self.zoomToFit(self.document.backgroundImage, in: size)
                }
        }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    //MARK: - Gesture: Panning

    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (self.document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
        }
        .onEnded { finalDragGestureValue in
            self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
        }
    }
    
    
    //MARK: - Helper functions
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        location = CGPoint(x: location.x + emojiPanOffset(for: emoji).width, y: location.y + emojiPanOffset(for: emoji).height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    //MARK: Constants
    private let defaultEmojiSize: CGFloat = 40
}
