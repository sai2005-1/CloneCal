import SwiftUI

@main
struct CloneCalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct CalendarEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var timeString: String
}

struct ContentView: View {
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = []
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventTime = Date()

    private let calendar = Calendar.current
    private let storageKey = "SavedCalendarEvents"

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .accentColor(.red)
                .padding(.horizontal)

                Divider()

                HStack {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(eventsForSelectedDate.count) Events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))

                if eventsForSelectedDate.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Events Scheduled")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(eventsForSelectedDate) { event in
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text(event.title)
                                    .font(.body)
                                Spacer()
                                Text(event.timeString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteEvent)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEvent = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                NavigationView {
                    Form {
                        Section(header: Text("Event Details")) {
                            TextField("Event Title", text: $newEventTitle)
                            DatePicker("Time", selection: $newEventTime, displayedComponents: .hourAndMinute)
                        }
                    }
                    .navigationTitle("New Event")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddEvent = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addEvent()
                                showingAddEvent = false
                            }
                            .disabled(newEventTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .onAppear(perform: loadEvents)
        }
    }

    var eventsForSelectedDate: [CalendarEvent] {
        events.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    func addEvent() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let newEvent = CalendarEvent(
            title: newEventTitle,
            date: selectedDate,
            timeString: formatter.string(from: newEventTime)
        )
        events.append(newEvent)
        saveEvents()
        newEventTitle = ""
    }

    func deleteEvent(at offsets: IndexSet) {
        let currentEvents = eventsForSelectedDate
        for index in offsets {
            let eventToDelete = currentEvents[index]
            events.removeAll { $0.id == eventToDelete.id }
        }
        saveEvents()
    }

    func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            events = decoded
        }
    }
}