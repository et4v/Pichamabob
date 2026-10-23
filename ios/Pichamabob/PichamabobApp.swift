//
//  PichamabobApp.swift
//  Pichamabob
//
//  Created by Emily Tew on 1/31/26.
//

import SwiftUI
import CoreData

@main
struct PichamabobApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
