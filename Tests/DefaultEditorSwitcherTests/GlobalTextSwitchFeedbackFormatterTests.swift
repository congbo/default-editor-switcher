import Combine
import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class GlobalTextSwitchFeedbackFormatterTests: XCTestCase {
    func testFeedbackUsesLocalizedHeadlineAndStatusSpecificDetails() {
        let formatter = GlobalTextSwitchFeedbackFormatter(
            localizer: StubFeedbackLocalizer(
                strings: [
                    "%d text types could not switch to %@.": "%d 个文本类型未能切换到 %@。",
                    "%@: Still opens in %@.": "%@: 仍然会在 %@ 中打开。",
                    "%@: This editor does not support this type on this Mac.": "%@: 这个编辑器在这台 Mac 上不支持此类型。",
                    "%@: macOS rejected the change (OSStatus %d).": "%@: macOS 拒绝了这次变更（OSStatus %d）。",
                ],
                languageCode: "zh-Hans"
            ),
            applicationLocator: StubFeedbackApplicationLocator(
                displayNamesByBundleID: ["com.apple.TextEdit": "TextEdit"]
            )
        )

        let feedback = formatter.feedback(
            for: GlobalTextSwitchReport(
                requestedBundleID: "com.example.partial",
                matchedCount: 1,
                mismatchedCount: 1,
                unsupportedCount: 1,
                writeFailedCount: 1,
                processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown", "public.python-script", "public.rust-source"],
                processedExtensions: ["txt", "md", "py", "rs"],
                sampleFailures: [
                    .init(
                        contentTypeIdentifier: "net.daringfireball.markdown",
                        scopeLabel: ".md",
                        role: .viewer,
                        status: "mismatched",
                        effectiveBundleID: "com.apple.TextEdit",
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.python-script",
                        scopeLabel: ".py",
                        role: .editor,
                        status: "unsupportedTarget",
                        effectiveBundleID: nil,
                        statusCode: nil
                    ),
                    .init(
                        contentTypeIdentifier: "public.rust-source",
                        scopeLabel: ".rs",
                        role: .viewer,
                        status: "writeFailed",
                        effectiveBundleID: "com.apple.TextEdit",
                        statusCode: -10810
                    ),
                ]
            ),
            requestedEditorName: "Partial Editor"
        )

        XCTAssertEqual(
            feedback,
            GlobalTextSwitchFeedback(
                headline: "3 个文本类型未能切换到 Partial Editor。",
                details: [
                    ".md: 仍然会在 TextEdit 中打开。",
                    ".py: 这个编辑器在这台 Mac 上不支持此类型。",
                    ".rs: macOS 拒绝了这次变更（OSStatus -10810）。",
                ]
            )
        )
    }

    func testFeedbackReturnsNilWhenSwitchFullyMatches() {
        let formatter = GlobalTextSwitchFeedbackFormatter(localizer: StubFeedbackLocalizer(strings: [:]))

        let feedback = formatter.feedback(
            for: GlobalTextSwitchReport(
                requestedBundleID: "com.microsoft.VSCode",
                matchedCount: 2,
                mismatchedCount: 0,
                unsupportedCount: 0,
                writeFailedCount: 0,
                processedContentTypeIdentifiers: ["public.plain-text", "net.daringfireball.markdown"],
                processedExtensions: ["txt", "md"],
                sampleFailures: []
            ),
            requestedEditorName: "Visual Studio Code"
        )

        XCTAssertNil(feedback)
    }
}

private final class StubFeedbackLocalizer: AppTextLocalizing {
    private let strings: [String: String]
    private let locale: Locale

    init(strings: [String: String], languageCode: String = "en") {
        self.strings = strings
        self.locale = Locale(identifier: languageCode)
    }

    var objectWillChangePublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func string(_ key: String) -> String {
        strings[key] ?? key
    }

    func formattedString(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}

private struct StubFeedbackApplicationLocator: ApplicationLocating {
    let displayNamesByBundleID: [String: String]

    func iconLookupPath(for bundleID: String) -> String? {
        nil
    }

    func displayName(for bundleID: String) -> String? {
        displayNamesByBundleID[bundleID]
    }
}
