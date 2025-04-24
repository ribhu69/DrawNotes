//
//  ContentView.swift
//  DrawNotes
//
//  Created by Arkaprava Ghosh on 24/04/25.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var contentMode: ContentMode = .dark

    var body: some View {
        ZStack {
            // Canvas View
            CanvasView(contentMode: $contentMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    
                    Spacer()
                    Button(action: {
                        contentMode = contentMode == .light ? .dark : .light
                    }) {
                        Image(systemName: contentMode == .light ? "sun.max.fill" : "moon.stars.fill")
                            .foregroundColor(contentMode == .light ? .yellow : .cyan)
                            .padding()
                            .background(Circle().fill(contentMode == .light ? Color.black.opacity(0.5) : Color.white.opacity(0.5)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
            .onAppear {
                contentMode = colorScheme == .dark ? .dark : .light
            }
        }
    }
}
