import SwiftUI

@main
struct PickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct Event: Identifiable {
    let id = UUID()
    var name: String
    var location: String
    var date: Date
    var tag: Int   // 0 to 3 = Tag 1 to Tag 4
}

// MARK: - Navigation (three tabs)

struct ContentView: View {
    @State private var darkMode = false
    @State private var selectedDate = Date()   // shared by Calendar and Schedule
    @State private var events = [
        Event(name: "Maths Test",  location: "Room 12",   date: Date(), tag: 0),
        Event(name: "Football",    location: "Field",     date: Date(), tag: 0),
        Event(name: "Art Project", location: "Art Room",  date: Date(), tag: 1),
        Event(name: "Choir",       location: "Hall",      date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tag: 1),
        Event(name: "Science Fair", location: "Lab",      date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, tag: 2)
    ]

    var body: some View {
        TabView {
            CalendarView(selectedDate: $selectedDate, events: events)
                .tabItem { Label("Calendar", systemImage: "calendar") }
            ScheduleView(events: $events, selectedDate: selectedDate)
                .tabItem { Label("Schedule", systemImage: "checklist") }
            SettingsView(darkMode: $darkMode)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}

// MARK: - Shared pieces

// Every screen uses this: background + title + padding
struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .padding(.vertical, 20)
                content
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// Rounded card
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// MARK: - Calendar

struct CalendarView: View {
    @Binding var selectedDate: Date
    let events: [Event]

    // Events that fall on the selected day
    var dayEvents: [Event] {
        events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        Screen(title: "Calendar") {
            Card {
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Divider()
                HStack {
                    Text("Time")
                    Spacer()
                    DatePicker("Time", selection: $selectedDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            Card {
                Text("Events today").font(.callout)
                if dayEvents.isEmpty {
                    Text("None").foregroundColor(.gray)
                }
                ForEach(dayEvents) { event in
                    HStack {
                        Text("\(event.name) - \(event.location)")
                        Spacer()
                        Text(event.date, style: .time)
                    }
                }
            }
        }
    }
}

// MARK: - Schedule

struct ScheduleView: View {
    @Binding var events: [Event]
    let selectedDate: Date   // from the Calendar tab
    @State private var selectedTag = 0

    var body: some View {
        Screen(title: "Schedule") {
            Picker("Tag", selection: $selectedTag) {
                ForEach(0..<4) { i in
                    Text("Tag \(i + 1)").tag(i)
                }
            }
            .pickerStyle(.segmented)

            // New events start on the date and time picked in the Calendar tab
            Button("Add event") {
                events.append(Event(name: "New Event", location: "Location", date: selectedDate, tag: selectedTag))
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($events) { $event in
                        if event.tag == selectedTag {
                            Card {
                                HStack {
                                    VStack(alignment: .leading) {
                                        TextField("Event", text: $event.name)
                                        TextField("Location", text: $event.location)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button {
                                        events.removeAll { $0.id == event.id }
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                                HStack {
                                    DatePicker("Date", selection: $event.date, displayedComponents: .date)
                                        .labelsHidden()
                                    DatePicker("Time", selection: $event.date, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Binding var darkMode: Bool
    @State private var pushOn = true

    var body: some View {
        NavigationStack {
            Screen(title: "Settings") {
                Card {
                    NavigationLink {
                        AccountView()
                    } label: {
                        HStack {
                            Text("Account").foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    Divider()
                    Toggle("Dark Mode", isOn: $darkMode)
                    Divider()
                    Toggle("Push Notifications", isOn: $pushOn)
                }
            }
        }
    }
}

struct AccountView: View {
    @State private var showAlert = false

    var body: some View {
        Screen(title: "Settings") {
            Card {
                HStack {
                    Text("Name")
                    Spacer()
                    Text("Zhonn Psmythe").foregroundColor(.gray)
                }
                Divider()
                HStack {
                    Text("Email")
                    Spacer()
                    Text("zhonn@zmail.com").foregroundColor(.gray)
                }
                Divider()
                HStack {
                    Text("Account Type")
                    Spacer()
                    Text("Free").foregroundColor(.gray)
                }
                Divider()
                HStack {
                    Text("Delete Account")
                    Spacer()
                    Button("Delete", role: .destructive) {
                        showAlert = true
                    }
                }
            }
        }
        .alert("Delete account?", isPresented: $showAlert) {
            Button("Delete", role: .destructive) { }   // does nothing for now
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone.")
        }
    }
}
