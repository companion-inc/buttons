import Foundation

public enum TemplateRenderer {
    public static func render(_ template: String, values: [String: String]) -> String {
        values.reduce(template) { partialResult, pair in
            partialResult.replacingOccurrences(of: "{{\(pair.key)}}", with: pair.value)
        }
    }
}
