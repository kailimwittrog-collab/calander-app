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

// One case per tab, so other screens (like Search) can switch tabs
enum AppTab: Hashable {
    case calendar, schedule, search, settings
}

// MARK: - Navigation (four tabs)

struct ContentView: View {
    @State private var darkMode = false
    @State private var tab: AppTab = .calendar
    @State private var selectedDate = Date()   // shared by Calendar and Schedule
    @State private var events = [
        Event(name: "Feetball :drool emoji:",    location: "Field",     date: Date(), tag: 0),
        Event(name: "Art Project", location: "Art Room",  date: Date(), tag: 1),
        Event(name: "Music or smt idk",       location: "Hall",      date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tag: 1),
        Event(name: "Science lesson yums", location: "Lab",      date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, tag: 2)
    ]

    var body: some View {
        TabView(selection: $tab) {
            CalendarView(selectedDate: $selectedDate, events: events)
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(AppTab.calendar)
            ScheduleView(events: $events, selectedDate: selectedDate)
                .tabItem { Label("Schedule", systemImage: "checklist") }
                .tag(AppTab.schedule)
            SearchView(events: events, tab: $tab, selectedDate: $selectedDate)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)
            SettingsView(darkMode: $darkMode)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
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

// MARK: - Search

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let destination: AppTab
    var date: Date? = nil   // if set, the Calendar jumps to this day
}

struct SearchView: View {
    let events: [Event]
    @Binding var tab: AppTab
    @Binding var selectedDate: Date
    @State private var query = ""

    // Things that aren't events but can still be searched for
    private let appItems: [SearchResult] = [
        SearchResult(title: "Calendar", subtitle: "Tab", icon: "calendar", destination: .calendar),
        SearchResult(title: "Schedule", subtitle: "Tab", icon: "checklist", destination: .schedule),
        SearchResult(title: "Settings", subtitle: "Tab", icon: "gearshape", destination: .settings),
        SearchResult(title: "Account", subtitle: "Settings", icon: "person.crop.circle", destination: .settings),
        SearchResult(title: "Dark Mode", subtitle: "Settings", icon: "moon", destination: .settings),
        SearchResult(title: "Push Notifications", subtitle: "Settings", icon: "bell", destination: .settings),
        SearchResult(title: "Leave a review", subtitle: "Settings", icon: "star", destination: .settings)
    ]

    var results: [SearchResult] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return [] }

        let eventResults = events
            .filter {
                $0.name.lowercased().contains(q)
                || $0.location.lowercased().contains(q)
                || "tag \($0.tag + 1)".contains(q)
            }
            .map {
                SearchResult(
                    title: $0.name,
                    subtitle: "\($0.location) · Tag \($0.tag + 1) · \($0.date.formatted(date: .abbreviated, time: .shortened))",
                    icon: "calendar.badge.clock",
                    destination: .calendar,
                    date: $0.date
                )
            }

        let itemResults = appItems.filter {
            $0.title.lowercased().contains(q) || $0.subtitle.lowercased().contains(q)
        }

        return eventResults + itemResults
    }

    var body: some View {
        Screen(title: "Search") {
            Card {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search events, settings...", text: $query)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                        }
                    }
                }
            }

            if query.isEmpty {
                Text("Type to search events, locations and settings")
                    .foregroundColor(.gray)
            } else if results.isEmpty {
                Text("No results").foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(results) { result in
                            Button {
                                if let date = result.date { selectedDate = date }
                                tab = result.destination
                            } label: {
                                Card {
                                    HStack {
                                        Image(systemName: result.icon)
                                            .frame(width: 28)
                                        VStack(alignment: .leading) {
                                            Text(result.title).foregroundColor(.primary)
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundColor(.gray)
                                    }
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
    @State private var buttonColor = Color.blue
    @State private var showFeedback = false

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

                // Changes its own colour every time it's tapped
                Button {
                    withAnimation {
                        buttonColor = Color(
                            hue: .random(in: 0...1),
                            saturation: .random(in: 0.6...0.9),
                            brightness: .random(in: 0.7...0.95)
                        )
                    }
                } label: {
                    Text("Change background colour")
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor)
                        .cornerRadius(12)
                }

                Button {
                    showFeedback = true
                } label: {
                    Label("Leave a review", systemImage: "star.bubble")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var feedback = ""
    @State private var showThanks = false

    var body: some View {
        Screen(title: "Leave a review") {
            Card {
                Text("How would you rate the app?")
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .onTapGesture { rating = star }
                    }
                }
                Divider()
                Text("Feedback")
                TextEditor(text: $feedback)
                    .frame(height: 140)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            Button("Submit") {
                // Nothing is sent anywhere yet - see notes below
                showThanks = true
            }
            .disabled(rating == 0)

            Button("Cancel", role: .cancel) { dismiss() }
        }
        .alert("Thanks for your feedback!", isPresented: $showThanks) {
            Button("OK") { dismiss() }
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
