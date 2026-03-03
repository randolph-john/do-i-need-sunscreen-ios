import SwiftUI

struct TimeChangeView: View {
    @Binding var isPresented: Bool
    let currentTime: Date
    let onTimeSelected: (Date) -> Void

    @State private var pickedDate: Date

    init(isPresented: Binding<Bool>, currentTime: Date, onTimeSelected: @escaping (Date) -> Void) {
        self._isPresented = isPresented
        self.currentTime = currentTime
        self.onTimeSelected = onTimeSelected
        self._pickedDate = State(initialValue: currentTime)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select a time to check UV conditions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                DatePicker(
                    "Time",
                    selection: $pickedDate,
                    in: dateRange,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button {
                    onTimeSelected(pickedDate)
                    isPresented = false
                } label: {
                    Text("Check this time")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FFED4E")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Change Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    /// Allow selecting times within the 48-hour forecast window
    private var dateRange: ClosedRange<Date> {
        let now = Date()
        let end = Calendar.current.date(byAdding: .hour, value: 47, to: now) ?? now
        return now...end
    }
}
