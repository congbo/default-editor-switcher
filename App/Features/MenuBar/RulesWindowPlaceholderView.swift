import SwiftUI

struct RulesWindowPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Rules Window")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Advanced language and custom extension rules arrive in later phases. Phase 02 keeps the resident menu utility focused on one-click global text switching.")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 420, minHeight: 260, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
