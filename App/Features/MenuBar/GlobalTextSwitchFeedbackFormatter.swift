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
            details: report.sampleFailures.compactMap(detailLine(for:))
        )
    }

    private func detailLine(for failure: GlobalTextSwitchReport.SampleFailure) -> String? {
        let scopeLabel = annotatedScopeLabel(for: failure)

        switch failure.status {
        case AssociationVerificationStatus.mismatched.rawValue:
            return localizer.formattedString(
                "%@: Still opens in %@.",
                scopeLabel,
                effectiveDisplayName(for: failure.effectiveBundleID)
            )
        case AssociationVerificationStatus.unsupportedTarget.rawValue:
            let baseMessage = localizer.formattedString(
                "%@: This editor does not support this type on this Mac.",
                scopeLabel
            )
            guard isDynamicContentTypeIdentifier(failure.contentTypeIdentifier) else {
                return baseMessage
            }

            return baseMessage + " " + localizer.string(
                "macOS only reports a dynamic UTI for this extension, so app matching is limited."
            )
        case AssociationVerificationStatus.writeFailed.rawValue:
            if let diagnostic = failure.diagnostic, !diagnostic.isEmpty {
                return "\(scopeLabel): \(diagnostic)"
            }

            return String(
                format: localizer.string("%@: macOS rejected the change (OSStatus %d)."),
                locale: Locale(identifier: "en_US_POSIX"),
                arguments: [scopeLabel, Int(failure.statusCode ?? -1)]
            )
        case AssociationVerificationStatus.pendingVerification.rawValue:
            return nil
        default:
            return scopeLabel
        }
    }

    private func isDynamicContentTypeIdentifier(_ contentTypeIdentifier: String) -> Bool {
        contentTypeIdentifier.hasPrefix("dyn.")
    }

    private func effectiveDisplayName(for bundleID: String?) -> String {
        guard let bundleID else {
            return localizer.string("another app")
        }

        return KnownEditors.knownEditor(for: bundleID)?.displayName
            ?? applicationLocator?.displayName(for: bundleID)
            ?? bundleID
    }

    private func annotatedScopeLabel(for failure: GlobalTextSwitchReport.SampleFailure) -> String {
        guard failure.role != .all else {
            return failure.scopeLabel
        }

        return "\(failure.scopeLabel) (\(roleDisplayName(for: failure.role)))"
    }

    private func roleDisplayName(for role: PreferredHandlerRole) -> String {
        switch role {
        case .all:
            return localizer.string("all")
        case .viewer:
            return localizer.string("viewer")
        case .editor:
            return localizer.string("editor")
        }
    }
}
