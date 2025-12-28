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
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color.black)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
