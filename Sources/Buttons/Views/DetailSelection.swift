import Foundation

enum DetailSelection: Equatable {
    case button(UUID)

    var buttonID: UUID? {
        switch self {
        case .button(let id):
            id
        }
    }
}
