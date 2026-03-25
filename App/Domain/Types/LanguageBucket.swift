import Foundation

enum LanguageBucket: String, CaseIterable, Hashable {
    case python
    case web
    case go
    case java
    case rust
    case markdown

    var extensions: Set<String> {
        switch self {
        case .python:
            return ["py"]
        case .web:
            return ["html", "css", "js", "jsx", "ts", "tsx", "vue", "svelte"]
        case .go:
            return ["go"]
        case .java:
            return ["java"]
        case .rust:
            return ["rs"]
        case .markdown:
            return ["md", "mdx"]
        }
    }
}
