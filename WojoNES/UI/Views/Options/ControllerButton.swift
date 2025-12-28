//
//  ControllerButton.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import SwiftUI

struct ControllerButton: View {
    let button: NESButton
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var viewModel: NESViewModel

    var body: some View {
        Button(action: action) {
            Text(viewModel.getControllerKeyBinding(button: button))
                .font(.caption)
                .foregroundColor(.white)
//                .padding(5)
                .background(isSelected ? Color.blue : Color.black)
                .cornerRadius(5)
        }
    }
}
