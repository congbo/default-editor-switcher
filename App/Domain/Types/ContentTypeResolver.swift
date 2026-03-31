import Foundation
import UniformTypeIdentifiers

enum ContentTypeResolver {
    struct Resolution: Hashable {
        let normalizedExtension: String
        let type: UTType?

        var isDeclared: Bool {
            type != nil
        }

        var conformsToText: Bool {
            type?.conforms(to: .text) == true
        }

        var conformsToSourceCode: Bool {
            type?.conforms(to: .sourceCode) == true
        }
    }

    static let builtInGlobalTextExtensions: Set<String> = [
        "txt",
        "md",
        "mdx",
        "json",
        "yaml",
        "yml",
        "toml",
        "xml",
        "csv",
        "log",
        "ini",
        "conf",
        "cfg",
        "env",
        "sh",
        "zsh",
        "bash",
        "fish",
        "py",
        "js",
        "jsx",
        "ts",
        "tsx",
        "go",
        "java",
        "rs",
        "html",
        "css",
        "vue",
        "svelte",
    ]

    static let defaultEnabledGlobalTextExtensions: Set<String> = builtInGlobalTextExtensions.subtracting(["html"])

    static func normalizeExtension(_ rawExtension: String) -> String {
        rawExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingPrefix(".")
    }

    static func extensions(for scope: FileScope) -> Set<String> {
        switch scope {
        case .allText:
            return defaultEnabledGlobalTextExtensions
        case .language(let bucket):
            return bucket.extensions
        case .customExtensions(let extensions):
            return Set(extensions.map { normalizeExtension($0) })
        }
    }

    static func resolve(for rawExtension: String) -> Resolution {
        let normalizedExtension = normalizeExtension(rawExtension)
        let resolvedType = UTType(filenameExtension: normalizedExtension)
        return Resolution(normalizedExtension: normalizedExtension, type: resolvedType)
    }

    static func resolutions(for scope: FileScope) -> [Resolution] {
        extensions(for: scope)
            .sorted()
            .map(resolve(for:))
    }

    static func resolutions(forExtensions extensions: Set<String>) -> [Resolution] {
        extensions
            .map(normalizeExtension)
            .sorted()
            .map(resolve(for:))
    }
}

private extension String {
    func trimmingPrefix(_ prefix: Character) -> String {
        guard first == prefix else {
            return self
        }

        return String(dropFirst())
    }
}
