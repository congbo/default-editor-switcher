import XCTest
@testable import DefaultEditorSwitcher

@MainActor
final class AppLanguageStoreTests: XCTestCase {
    func testDefaultLanguageIsSystem() {
        let store = AppLanguageStore(
            userDefaults: makeUserDefaults(testName: #function),
            systemLocaleProvider: { Locale(identifier: "fr_FR") }
        )

        XCTAssertEqual(store.selectedLanguage, .system)
        XCTAssertEqual(store.effectiveLanguage, .english)
        XCTAssertEqual(store.effectiveLocale.identifier, "en")
    }

    func testLanguageSelectionPersistsAcrossInstances() {
        let userDefaults = makeUserDefaults(testName: #function)
        let store = AppLanguageStore(userDefaults: userDefaults)

        store.selectedLanguage = .english
        XCTAssertEqual(AppLanguageStore(userDefaults: userDefaults).selectedLanguage, .english)

        store.selectedLanguage = .simplifiedChinese
        XCTAssertEqual(AppLanguageStore(userDefaults: userDefaults).selectedLanguage, .simplifiedChinese)
    }

    func testLocaleMappingMatchesLanguageChoice() {
        let store = AppLanguageStore(
            userDefaults: makeUserDefaults(testName: #function),
            systemLocaleProvider: { Locale(identifier: "ja_JP") }
        )

        store.selectedLanguage = .system
        XCTAssertEqual(store.effectiveLanguage, .english)
        XCTAssertEqual(store.effectiveLocale.identifier, "en")

        store.selectedLanguage = .english
        XCTAssertEqual(store.effectiveLanguage, .english)
        XCTAssertEqual(store.effectiveLocale.identifier, "en")

        store.selectedLanguage = .simplifiedChinese
        XCTAssertEqual(store.effectiveLanguage, .simplifiedChinese)
        XCTAssertEqual(store.effectiveLocale.identifier, "zh-Hans")
    }

    func testSystemLanguageTreatsChineseLocalesAsSimplifiedChinese() {
        let chineseLocales = ["zh-Hans", "zh-HK", "zh-TW"]

        for localeIdentifier in chineseLocales {
            let store = AppLanguageStore(
                userDefaults: makeUserDefaults(testName: "\(#function).\(localeIdentifier)"),
                systemLocaleProvider: { Locale(identifier: localeIdentifier) }
            )

            XCTAssertEqual(store.effectiveLanguage, .simplifiedChinese)
            XCTAssertEqual(store.effectiveLocale.identifier, "zh-Hans")
        }
    }

    func testSystemLanguageFallsBackToEnglishForUnsupportedLocales() {
        let unsupportedLocales = ["fr_FR", "de_DE", "ja_JP"]

        for localeIdentifier in unsupportedLocales {
            let store = AppLanguageStore(
                userDefaults: makeUserDefaults(testName: "\(#function).\(localeIdentifier)"),
                systemLocaleProvider: { Locale(identifier: localeIdentifier) }
            )

            XCTAssertEqual(store.effectiveLanguage, .english)
            XCTAssertEqual(store.effectiveLocale.identifier, "en")
        }
    }

    func testAppLocalizerReadsSelectedLanguageBundle() {
        let store = AppLanguageStore(
            userDefaults: makeUserDefaults(testName: #function),
            systemLocaleProvider: { Locale(identifier: "fr_FR") }
        )
        let localizer = AppLocalizer(languageStore: store)

        store.selectedLanguage = .english
        XCTAssertEqual(localizer.string("Settings"), "Settings")

        store.selectedLanguage = .simplifiedChinese
        XCTAssertEqual(localizer.string("Settings"), "设置")
    }

    func testAppLocalizerUsesResolvedSystemLanguageBundle() {
        let englishStore = AppLanguageStore(
            userDefaults: makeUserDefaults(testName: #function),
            systemLocaleProvider: { Locale(identifier: "fr_FR") }
        )
        let englishLocalizer = AppLocalizer(languageStore: englishStore)

        englishStore.selectedLanguage = .system
        XCTAssertEqual(englishLocalizer.string("Settings"), "Settings")
        XCTAssertEqual(englishLocalizer.string("More"), "More")
        XCTAssertEqual(englishLocalizer.string("Supported Editors"), "Supported Editors")
        XCTAssertEqual(englishLocalizer.string("No Eligible Editors Found"), "No Eligible Editors Found")

        let chineseStore = AppLanguageStore(
            userDefaults: makeUserDefaults(testName: "\(#function).zh"),
            systemLocaleProvider: { Locale(identifier: "zh-HK") }
        )
        let chineseLocalizer = AppLocalizer(languageStore: chineseStore)

        chineseStore.selectedLanguage = .system
        XCTAssertEqual(chineseLocalizer.string("Settings"), "设置")
        XCTAssertEqual(chineseLocalizer.string("More"), "更多")
        XCTAssertEqual(chineseLocalizer.string("Supported Editors"), "支持的编辑器")
        XCTAssertEqual(chineseLocalizer.string("No Eligible Editors Found"), "未找到符合条件的编辑器")
    }

    private func makeUserDefaults(testName: String) -> UserDefaults {
        let suiteName = "AppLanguageStoreTests.\(testName)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
