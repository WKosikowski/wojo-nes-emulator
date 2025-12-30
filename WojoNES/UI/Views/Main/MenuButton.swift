//
//  MenuButton.swift
//  WojoNES
//
//  Created by Wojciech Kosikowski on 28/12/2025.
//

import SwiftUI

/// A reusable menu button component for the overlay menu bar.
/// Displays an SF Symbol icon alongside a text label and provides hover feedback.
/// The button scales up and brightens on hover for visual feedback.
struct MenuButton: View {
    /// The SF Symbol name for the button's icon
    let icon: String
    /// The text label displayed alongside the icon
    let label: String
    /// The closure executed when the button is clicked
    let action: () -> Void
    /// Tracks whether the mouse is hovering over the button
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon image from SF Symbols
                Image(systemName: icon)
                    .font(.system(size: 14))
                // Button label text
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            // Expand to fill available width, content left-aligned
            .frame(maxWidth: .infinity, alignment: .leading)
            // Background colour changes on hover
            .background(Color.white.opacity(isHovering ? 0.2 : 0.1))
            .cornerRadius(8)
            // Subtle scale animation on hover (5% increase)
            .scaleEffect(isHovering ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        // Detect mouse hover and update state
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
