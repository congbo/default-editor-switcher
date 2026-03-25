import Foundation

struct GlobalTextSwitchFeedback: Equatable {
    let headline: String
    let details: [String]
}

@MainActor
protocol GlobalTextSwitchFeedbackFormatting {
    func feedback(
        for report: GlobalTextSwitchReport,
        requestedEditorName: String
    ) -> GlobalTextSwitchFeedback?
}

@MainActor
struct GlobalTextSwitchFeedbackFormatter: GlobalTextSwitchFeedbackFormatting {
    let localizer: any AppTextLocalizing
    let applicationLocator: ApplicationLocating?

    init(
        localizer: any AppTextLocalizing,
        applicationLocator: ApplicationLocating? = nil
    ) {
        self.localizer = localizer
        self.applicationLocator = applicationLocator
    }

    func feedback(
        for report: GlobalTextSwitchReport,
        requestedEditorName: String
    ) -> GlobalTextSwitchFeedback? {
        guard report.affectedCount > 0 else {
            return nil
        }

        return GlobalTextSwitchFeedback(
            headline: localizer.formattedString(
                "%d text types could not switch to %@.",
                report.affectedCount,
                requestedEditorName
            ),
            details: report.sampleFailures.prefix(3).map(detailLine(for:))
        )
    }

    private func detailLine(for failure: GlobalTextSwitchReport.SampleFailure) -> String {
        switch failure.status {
        case AssociationVerificationStatus.mismatched.rawValue:
            return localizer.formattedString(
                "%@: Still opens in %@.",
                failure.scopeLabel,
                effectiveDisplayName(for: failure.effectiveBundleID)
            )
        case AssociationVerificationStatus.unsupportedTarget.rawValue:
            return localizer.formattedString(
                "%@: This editor does not support this type on this Mac.",
                failure.scopeLabel
            )
        case AssociationVerificationStatus.writeFailed.rawValue:
            return String(
                format: localizer.string("%@: macOS rejected the change (OSStatus %d)."),
                locale: Locale(identifier: "en_US_POSIX"),
                arguments: [failure.scopeLabel, Int(failure.statusCode ?? -1)]
            )
        default:
            return failure.scopeLabel
        }
    }

    private func effectiveDisplayName(for bundleID: String?) -> String {
        guard let bundleID else {
            return localizer.string("another app")
        }

        return KnownEditors.knownEditor(for: bundleID)?.displayName
            ?? applicationLocator?.displayName(for: bundleID)
            ?? bundleID
    }
}
