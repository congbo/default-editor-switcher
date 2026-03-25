import XCTest
@testable import DefaultEditorSwitcher

final class FileScopeCatalogTests: XCTestCase {
    func testAllTextIncludesSourceCodeExtensions() {
        let extensions = ContentTypeResolver.extensions(for: .allText)

        XCTAssertTrue(extensions.isSuperset(of: ["py", "ts", "rs", "md", "json"]))
    }

    func testMarkdownBucketContainsExpectedExtensions() {
        let extensions = ContentTypeResolver.extensions(for: .language(.markdown))

        XCTAssertEqual(extensions, ["md", "mdx"])
    }

    func testWebBucketContainsExpectedExtensions() {
        let extensions = ContentTypeResolver.extensions(for: .language(.web))

        XCTAssertEqual(extensions, ["html", "css", "js", "jsx", "ts", "tsx", "vue", "svelte"])
    }

    func testExtensionNormalizationLowercasesInputBeforeLookup() {
        let uppercased = ContentTypeResolver.resolve(for: "TSX")
        let lowercased = ContentTypeResolver.resolve(for: "tsx")

        XCTAssertEqual(uppercased.normalizedExtension, "tsx")
        XCTAssertEqual(uppercased.normalizedExtension, lowercased.normalizedExtension)
        XCTAssertEqual(uppercased.type, lowercased.type)
    }
}
