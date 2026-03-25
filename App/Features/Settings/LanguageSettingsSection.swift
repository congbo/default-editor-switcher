import SwiftUI

struct LanguageSettingsSection: View {
    @ObservedObject var languageStore: AppLanguageStore

    var body: some View {
        Section("Language") {
            VStack(alignment: .leading, spacing: 6) {
                LabeledContent("Language") {
                    Picker("Language", selection: $languageStore.selectedLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            switch language {
                            case .system:
                                Text("Follow System").tag(language)
                            case .english:
                                Text("English").tag(language)
                            case .simplifiedChinese:
                                Text("简体中文").tag(language)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 170)
                }

                Text("Use the system language by default, or force English or Chinese for app-owned copy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
