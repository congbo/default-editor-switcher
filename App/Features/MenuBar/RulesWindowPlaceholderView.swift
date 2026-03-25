import SwiftUI

struct RulesWindowPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Advanced Rules Window")
                .font(.system(size: 20, weight: .semibold))

            Text("Advanced language and custom extension rules arrive in later phases. Phase 02 keeps the resident menu utility focused on one-click global text switching.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .background(Color(red: 0.957, green: 0.945, blue: 0.918))
    }
}
