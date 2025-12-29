//
//  NESView.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 23/12/2025.
//

import CoreVideo
import Foundation
import MetalKit
import SwiftUI

struct NESView: View {
    // MARK: SwiftUI Properties

    @StateObject private var viewModel = NESViewModel()

    @State private var isRunning = false

    // MARK: Content Properties

    var body: some View {
        VStack {
            ZStack {
                MetalBitmapView(pixmap: viewModel.pixelMap) { controller in
                    viewModel.nesControllerEvent(controller: controller)
                }
                .aspectRatio(CGSize(width: 256, height: 240), contentMode: .fit)
//                .frame(width: 256 * 2, height: 240 * 2)
                .focusable() // button press handling
            }
            // Controls
            HStack {
                Button(action: {
                    if isRunning {
                        viewModel.pause()
                    } else {
                        viewModel.resume()
                    }
                    isRunning.toggle()
                }) {
                    Text(isRunning ? "Pause" : "Resume")
                }

                Button("Reset") {
                    viewModel.reset()
                }

                Button("Load ROM") {
                    viewModel.loadROM()
                }
            }
            .padding()

            // Debug Info
            VStack(alignment: .leading) {
                Text("FPS: \(viewModel.fps)")
            }
            .padding()

            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}
