import SwiftUI

struct ClipboardListView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 6) {
                ForEach(viewModel.displayItems) { item in
                    ClipboardCard(item: item)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
