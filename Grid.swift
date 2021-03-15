//
//  Grid.swift
//  Memorize
//
//  Created by Vicente Montoya on 8/13/20.
//  Copyright © 2020 Vicente Montoya. All rights reserved.
//

import SwiftUI

struct Grid<Item, ID, ItemView>: View where ID: Hashable, ItemView: View{
    private  var items: [Item]
    private var viewForItem: (Item) -> ItemView
    private var aspectRatio: CGFloat
    private var id: KeyPath<Item, ID>
    
    init(items: [Item], id: KeyPath<Item, ID>, aspectRatio: CGFloat, viewForItem: @escaping (Item) -> ItemView){
        self.items = items
        self.viewForItem = viewForItem
        self.aspectRatio = aspectRatio
        self.id = id
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.body(for: GridLayout(itemCount: self.items.count, nearAspectRatio: Double(self.aspectRatio), in: geometry.size))
        }
    }
    
    private func body (for layout: GridLayout) -> some View{
        ForEach(items, id: id){ item in
            self.body(for: item, in: layout)
        }
    }
    
    private func body(for item: Item, in layout: GridLayout) -> some View{
        let index = self.items.firstIndex(where: { item[keyPath: id] == $0[keyPath: id] })
        return viewForItem(item)
            .frame(width: layout.itemSize.width, height: layout.itemSize.height)
            .position(layout.location(ofItemAt: index!))
    }
}

extension Grid where Item: Identifiable, ID == Item.ID {
    
    init(items: [Item], aspectRatio: CGFloat, viewForItem: @escaping (Item) -> ItemView){
        self.init(items: items, id: \Item.id, aspectRatio: aspectRatio, viewForItem: viewForItem)
    }

}
