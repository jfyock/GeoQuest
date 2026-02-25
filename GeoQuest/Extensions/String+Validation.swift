import Foundation

extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }

    var isValidSecretCode: Bool {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.count >= AppConstants.minSecretCodeLength
            && trimmed.count <= AppConstants.maxSecretCodeLength
            && trimmed.range(of: #"^[A-Za-z0-9]+$"#, options: .regularExpression) != nil
    }

    var isValidDisplayName: Bool {
        let trimmed = trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= 30
    }

    var isValidPassword: Bool {
        count >= 6
    }

    func truncated(to maxLength: Int) -> String {
        if count <= maxLength { return self }
        return String(prefix(maxLength))
    }
}
