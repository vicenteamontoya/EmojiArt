//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Vicente Montoya on 9/4/20.
//  Copyright © 2020 Vicente Montoya. All rights reserved.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    @State var showPaletteEditor = false
    
    var body: some View {
        HStack{
            Stepper(onIncrement: {self.chosenPalette = self.document.palette(after: self.chosenPalette)},
                    onDecrement: {self.chosenPalette = self.document.palette(before: self.chosenPalette)},
                    label: { EmptyView() })
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
            Image(systemName: "keyboard").imageScale(.large)
                .onTapGesture {
                    self.showPaletteEditor = true
            }
            .sheet(isPresented: $showPaletteEditor){
                PaletteEditor(chosenPalette: self.$chosenPalette, isShowing: self.$showPaletteEditor)
                    .environmentObject(self.document)
                    .frame(minWidth: 300, minHeight: 500)
            }
            
        }
        .fixedSize(horizontal: true, vertical: false)
    } 
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}

struct PaletteEditor: View{
    @EnvironmentObject var document: EmojiArtDocument
    
    @Binding var chosenPalette: String
    
    @Binding var isShowing: Bool
    
    @State private var paletteName: String = ""
    
    @State private var emojiToAdd: String = ""
    
    
    
    var body: some View {
        VStack(spacing: 0){
            
            ZStack{
                Text("Palette Editor").font(.headline).padding()
                HStack{
                    Spacer()
                    Button(action: {self.isShowing = false}, label: { Text( "Done") }).padding()
                }
            }
            
            Divider()
            Form{
                Section{
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began{
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojiToAdd, onEditingChanged: { began in
                        if !began{
                            self.document.addEmoji(self.emojiToAdd, toPalette: self.chosenPalette)
                            self.emojiToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")){
                    
                    Grid ( items: chosenPalette.map{ String($0) }, id: \.self , aspectRatio: 1){ emoji in
                        Text(emoji).font(Font.system(size: self.fontSize)).onTapGesture {
                                self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                        }
                    }
                    .frame(height: height)
                }
            }
        }
        .onAppear{ self.paletteName = self.document.paletteNames[self.paletteName] ?? "" }
    }
    
    //MARK: - Drawing constants
    
    private var height: CGFloat {
        CGFloat( (chosenPalette.count - 1) / 6 ) * 70 + 70
    }
    
    private let fontSize: CGFloat = 40
}
