//
//  VoiceToTextApp.swift
//  VoiceToText
//
//  Created by Artem Mir on 21.03.26.
//

import SwiftUI

@main
struct VoiceToTextApp: App {
    private let appContainer = AppContainer.live

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: appContainer.makeTranscriptionViewModel())
        }
    }
}
