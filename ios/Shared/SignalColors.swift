import SwiftUI

extension SignalLevel {
    var color: Color {
        switch self {
        case .red: .red
        case .yellow: .yellow
        case .green: .green
        case .stale: .gray
        }
    }
}
