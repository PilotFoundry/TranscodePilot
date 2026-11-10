import SwiftUI

/// Shared visual constants for the app. Keep values here rather than scattering
/// ad-hoc numbers through views so light/dark and density reviews stay coherent.
enum Design {
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 10
    }

    enum Palette {
        /// System accent for controls, selection and drag feedback.
        static var accent: Color { Color.accentColor }
        /// Orange is reserved for the brand mark/app icon, not primary controls.
        static var brand: Color { Color.orange }
    }
}
