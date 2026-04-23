//
//  ContentView.swift
//  test
//
//  Created by Jerome Barrow on 4/21/26.
//

//
// // PlanItOut.swift
// Plan It Out — Student Planner
// Drop this file into a new SwiftUI Xcode project (iOS 17+).
// Set PlanItOutApp as the @main entry point, or replace your App struct with the one below.

import SwiftUI

import Combine

// MARK: - App Entry


struct PlanItOutApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Models

struct ClassItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var fullName: String
    var day: Int          // 0 = Mon … 4 = Fri
    var startHour: Double // e.g. 9.0 = 9:00 AM, 9.5 = 9:30 AM
    var duration: Double  // hours
    var location: String
    var colorIndex: Int
}

struct Assignment: Identifiable, Codable {
    var id = UUID()
    var title: String
    var subject: String
    var dueDate: Date
    var priority: Priority
    var isDone: Bool

    enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low:    return .green
            case .medium: return Color(red: 0.96, green: 0.62, blue: 0.04)
            case .high:   return .red
            }
        }
        var bgColor: Color {
            switch self {
            case .low:    return Color.green.opacity(0.12)
            case .medium: return Color.orange.opacity(0.12)
            case .high:   return Color.red.opacity(0.12)
            }
        }
    }
}

struct StudySession: Identifiable, Codable {
    var id = UUID()
    var subject: String
    var duration: Int  // minutes
    var notes: String
    var date: Date = Date()
}

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var streak: Int
    var completedToday: Bool
}

struct Goal: Identifiable, Codable {
    var id = UUID()
    var title: String
    var deadline: Date
    var progress: Double  // 0.0 – 1.0
}

// MARK: - Store (ObservableObject)

class PlannerStore: ObservableObject {
    @Published var classes: [ClassItem] = [
        ClassItem(name: "CS 301",   fullName: "Data Structures",   day: 0, startHour: 9,  duration: 1.5, location: "Hall A",    colorIndex: 0),
        ClassItem(name: "MATH 201", fullName: "Calculus II",       day: 1, startHour: 11, duration: 1,   location: "Room 204",  colorIndex: 1),
        ClassItem(name: "ENG 101",  fullName: "Technical Writing", day: 2, startHour: 14, duration: 1.5, location: "Arts Bldg", colorIndex: 2),
        ClassItem(name: "CS 301",   fullName: "Data Structures",   day: 3, startHour: 9,  duration: 1.5, location: "Hall A",    colorIndex: 0),
        ClassItem(name: "PHYS 210", fullName: "Physics Lab",       day: 4, startHour: 13, duration: 2,   location: "Lab 101",   colorIndex: 3),
    ]

    @Published var assignments: [Assignment] = {
        let cal = Calendar.current
        let today = Date()
        return [
            Assignment(title: "Data Structures Project",  subject: "CS 301",   dueDate: cal.date(byAdding: .day, value: 0,  to: today)!, priority: .high,   isDone: false),
            Assignment(title: "Calculus Problem Set #5",  subject: "MATH 201", dueDate: cal.date(byAdding: .day, value: 3,  to: today)!, priority: .medium, isDone: false),
            Assignment(title: "Research Paper Draft",     subject: "ENG 101",  dueDate: cal.date(byAdding: .day, value: 6,  to: today)!, priority: .high,   isDone: false),
            Assignment(title: "Physics Lab Report",       subject: "PHYS 210", dueDate: cal.date(byAdding: .day, value: 2,  to: today)!, priority: .medium, isDone: true),
        ]
    }()

    @Published var sessions: [StudySession] = [
        StudySession(subject: "CS 301",   duration: 50, notes: "Reviewed trees & graphs"),
        StudySession(subject: "MATH 201", duration: 30, notes: "Practice integrals"),
    ]

    @Published var habits: [Habit] = [
        Habit(name: "Review lecture notes",    streak: 5,  completedToday: false),
        Habit(name: "30 min reading",          streak: 12, completedToday: true),
        Habit(name: "Exercise",                streak: 3,  completedToday: false),
        Habit(name: "No phone before studying", streak: 8, completedToday: true),
    ]

    @Published var goals: [Goal] = {
        let cal = Calendar.current
        let today = Date()
        return [
            Goal(title: "Finish CS 301 project",        deadline: cal.date(byAdding: .day, value: 0, to: today)!, progress: 0.60),
            Goal(title: "Read 2 textbook chapters",     deadline: cal.date(byAdding: .day, value: 3, to: today)!, progress: 1.0),
            Goal(title: "Complete math problem sets",   deadline: cal.date(byAdding: .day, value: 3, to: today)!, progress: 0.40),
        ]
    }()

    // Pomodoro state
    @Published var pomMode: PomMode = .work
    @Published var pomSecondsLeft: Int = 25 * 60
    @Published var pomRunning = false
    private var timer: AnyCancellable?

    enum PomMode { case work, shortBreak }

    func togglePomodoro() {
        if pomRunning {
            timer?.cancel()
            pomRunning = false
        } else {
            pomRunning = true
            timer = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if self.pomSecondsLeft > 0 {
                        self.pomSecondsLeft -= 1
                    } else {
                        self.pomRunning = false
                        self.timer?.cancel()
                        self.pomMode = self.pomMode == .work ? .shortBreak : .work
                        self.pomSecondsLeft = self.pomMode == .work ? 25 * 60 : 5 * 60
                    }
                }
        }
    }

    func resetPomodoro() {
        timer?.cancel()
        pomRunning = false
        pomSecondsLeft = pomMode == .work ? 25 * 60 : 5 * 60
    }

    func switchPomMode(_ mode: PomMode) {
        timer?.cancel()
        pomRunning = false
        pomMode = mode
        pomSecondsLeft = mode == .work ? 25 * 60 : 5 * 60
    }
}

// MARK: - Class Colors

let classColors: [(bg: Color, accent: Color)] = [
    (Color(red: 0.93, green: 0.93, blue: 1.0),   Color(red: 0.39, green: 0.40, blue: 0.95)),
    (Color(red: 1.0,  green: 0.97, blue: 0.88),  Color(red: 0.96, green: 0.62, blue: 0.04)),
    (Color(red: 0.86, green: 0.99, blue: 0.91),  Color(red: 0.13, green: 0.77, blue: 0.37)),
    (Color(red: 0.99, green: 0.91, blue: 0.95),  Color(red: 0.93, green: 0.28, blue: 0.60)),
    (Color(red: 0.88, green: 0.95, blue: 1.0),   Color(red: 0.05, green: 0.65, blue: 0.91)),
]

// MARK: - Helpers

func daysUntilLabel(_ date: Date) -> String {
    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
    if days < 0  { return "Overdue" }
    if days == 0 { return "Today" }
    if days == 1 { return "Tomorrow" }
    return "\(days)d left"
}

func daysUntilColor(_ date: Date) -> Color {
    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: date)).day ?? 0
    if days < 0  { return .red }
    if days <= 1 { return Color(red: 0.96, green: 0.62, blue: 0.04) }
    return .secondary
}

func formatSeconds(_ s: Int) -> String {
    String(format: "%02d:%02d", s / 60, s % 60)
}

// MARK: - Root Content View

struct ContentView: View {
    @StateObject private var store = PlannerStore()

    var body: some View {
        TabView {
            ScheduleView()
                .tabItem { Label("Schedule",    systemImage: "calendar") }
            AssignmentsView()
                .tabItem { Label("Assignments", systemImage: "checkmark.rectangle") }
            StudyView()
                .tabItem { Label("Study",       systemImage: "timer") }
            HabitsView()
                .tabItem { Label("Habits",      systemImage: "target") }
        }
        .environmentObject(store)
        .tint(Color(red: 0.31, green: 0.28, blue: 0.95))
    }
}

// MARK: - Schedule View

struct ScheduleView: View {
    @EnvironmentObject var store: PlannerStore
    @State private var showAdd = false

    let days   = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    let hours  = Array(8...20)
    let hourH: CGFloat = 60

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 0) {
                    // Day header row
                    HStack(spacing: 0) {
                        Spacer().frame(width: 44)
                        ForEach(days.indices, id: \.self) { i in
                            Text(days[i])
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground))
                                .overlay(Rectangle().frame(height: 0.5).foregroundColor(.blue), alignment: .bottom)
                        }
                    }
                    .frame(width: 44 + CGFloat(days.count) * 120)

                    // Time grid
                    ZStack(alignment: .topLeading) {
                        // Background grid lines
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: hourH)
                                    .overlay(Rectangle().frame(height: 0.5).foregroundColor(.blue).opacity(0.4), alignment: .bottom)
                            }
                        }
                        .frame(width: 44 + CGFloat(days.count) * 120)

                        // Time labels
                        VStack(spacing: 0) {
                            ForEach(hours, id: \.self) { h in
                                HStack {
                                    Text(hourLabel(h))
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                        .frame(width: 38, alignment: .trailing)
                                    Spacer()
                                }
                                .frame(height: hourH, alignment: .top)
                                .padding(.top, 4)
                            }
                        }

                        // Class blocks
                        ForEach(store.classes) { cls in
                            let col = classColors[cls.colorIndex % classColors.count]
                            let xOff: CGFloat = 44 + CGFloat(cls.day) * 120 + 2
                            let yOff: CGFloat = CGFloat(cls.startHour - 8) * hourH + 2
                            let blockH: CGFloat = CGFloat(cls.duration) * hourH - 4

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cls.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(col.accent)
                                if blockH > 40 {
                                    Text(cls.fullName)
                                        .font(.system(size: 10))
                                        .foregroundStyle(col.accent.opacity(0.75))
                                }
                                if !cls.location.isEmpty && blockH > 60 {
                                    Text(cls.location)
                                        .font(.system(size: 9))
                                        .foregroundStyle(col.accent.opacity(0.55))
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .frame(width: 116, height: blockH, alignment: .topLeading)
                            .background(col.bg)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(col.accent.opacity(0.4), lineWidth: 0.5)
                            )
                            .overlay(
                                Rectangle()
                                    .fill(col.accent)
                                    .frame(width: 3)
                                    .cornerRadius(2),
                                alignment: .leading
                            )
                            .offset(x: xOff, y: yOff)
                        }
                    }
                    .frame(
                        width:  44 + CGFloat(days.count) * 120,
                        height: CGFloat(hours.count) * hourH
                    )
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddClassSheet()
                    .environmentObject(store)
            }
        }
    }

    func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "a" : "p"
        let display = h > 12 ? h - 12 : h
        return "\(display)\(suffix)"
    }
}

// MARK: - Add Class Sheet

struct AddClassSheet: View {
    @EnvironmentObject var store: PlannerStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var fullName = ""
    @State private var day = 0
    @State private var startHour = 9.0
    @State private var duration = 1.5
    @State private var location = ""
    @State private var colorIndex = 0

    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Course info") {
                    TextField("Code (e.g. CS 301)", text: $name)
                    TextField("Full name", text: $fullName)
                    TextField("Location (optional)", text: $location)
                }
                Section("Time") {
                    Picker("Day", selection: $day) {
                        ForEach(days.indices, id: \.self) { i in
                            Text(days[i]).tag(i)
                        }
                    }
                    Stepper("Start: \(hourLabel(Int(startHour)))", value: $startHour, in: 8...20, step: 0.5)
                    Stepper("Duration: \(String(format: "%.1fh", duration))", value: $duration, in: 0.5...4, step: 0.5)
                }
                Section("Color") {
                    HStack(spacing: 14) {
                        ForEach(classColors.indices, id: \.self) { i in
                            Circle()
                                .fill(classColors[i].accent)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: colorIndex == i ? 2.5 : 0)
                                )
                                .onTapGesture { colorIndex = i }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.isEmpty else { return }
                        store.classes.append(ClassItem(name: name, fullName: fullName, day: day, startHour: startHour, duration: duration, location: location, colorIndex: colorIndex))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    func hourLabel(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let d = h > 12 ? h - 12 : h
        return "\(d):00 \(suffix)"
    }
}

// MARK: - Assignments View

struct AssignmentsView: View {
    @EnvironmentObject var store: PlannerStore
    @State private var filter: AssignFilter = .all
    @State private var showAdd = false

    enum AssignFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case done = "Done"
    }

    var filtered: [Assignment] {
        let sorted = store.assignments.sorted { $0.dueDate < $1.dueDate }
        switch filter {
        case .all:     return sorted
        case .pending: return sorted.filter { !$0.isDone }
        case .done:    return sorted.filter { $0.isDone }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Stats row
                Section {
                    HStack(spacing: 12) {
                        StatCard(value: store.assignments.filter { $0.priority == .high && !$0.isDone }.count,
                                 label: "High priority", color: .red)
                        StatCard(value: store.assignments.filter { daysUntilLabel($0.dueDate) != "Overdue" && !$0.isDone && Calendar.current.dateComponents([.day], from: Date(), to: $0.dueDate).day ?? 99 <= 7 }.count,
                                 label: "Due this week", color: .orange)
                        StatCard(value: store.assignments.filter { $0.isDone }.count,
                                 label: "Completed", color: .green)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // Filter picker
                Section {
                    Picker("Filter", selection: $filter) {
                        ForEach(AssignFilter.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)

                // Assignments
                Section {
                    ForEach(filtered) { asgn in
                        AssignmentRow(asgn: asgn)
                    }
                    .onDelete { indexSet in
                        let ids = indexSet.map { filtered[$0].id }
                        store.assignments.removeAll { ids.contains($0.id) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Assignments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddAssignmentSheet().environmentObject(store)
            }
        }
    }
}

struct StatCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AssignmentRow: View {
    @EnvironmentObject var store: PlannerStore
    let asgn: Assignment

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                if let i = store.assignments.firstIndex(where: { $0.id == asgn.id }) {
                    store.assignments[i].isDone.toggle()
                }
            } label: {
                Image(systemName: asgn.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(asgn.isDone ? Color(red: 0.31, green: 0.28, blue: 0.95) : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(asgn.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(asgn.isDone)
                        .foregroundStyle(asgn.isDone ? .secondary : .primary)
                    Text(asgn.priority.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(asgn.priority.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(asgn.priority.bgColor)
                        .cornerRadius(6)
                }
                Text(asgn.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(daysUntilLabel(asgn.dueDate))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(daysUntilColor(asgn.dueDate))
                Text(asgn.dueDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .opacity(asgn.isDone ? 0.55 : 1)
    }
}

struct AddAssignmentSheet: View {
    @EnvironmentObject var store: PlannerStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subject = ""
    @State private var dueDate = Date()
    @State private var priority = Assignment.Priority.medium

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Assignment title", text: $title)
                    TextField("Subject / Course", text: $subject)
                }
                Section {
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    Picker("Priority", selection: $priority) {
                        ForEach(Assignment.Priority.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                }
            }
            .navigationTitle("Add Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !title.isEmpty else { return }
                        store.assignments.append(Assignment(title: title, subject: subject, dueDate: dueDate, priority: priority, isDone: false))
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Study View

struct StudyView: View {
    @EnvironmentObject var store: PlannerStore
    @State private var showLog = false
    @State private var newSubject = ""
    @State private var newDuration = 25
    @State private var newNotes = ""

    var totalMinutes: Int { store.sessions.reduce(0) { $0 + $1.duration } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PomodoroCard()

                    // Session Log button
                    HStack {
                        Text("Today's log")
                            .font(.headline)
                        Spacer()
                        Text("\(totalMinutes) min total")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0.93, green: 0.93, blue: 1.0))
                            .foregroundStyle(Color(red: 0.31, green: 0.28, blue: 0.95))
                            .cornerRadius(8)
                        Button { showLog = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color(red: 0.31, green: 0.28, blue: 0.95))
                        }
                    }
                    .padding(.horizontal)

                    ForEach(store.sessions) { s in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.93, green: 0.93, blue: 1.0))
                                    .frame(width: 50, height: 50)
                                Text("\(s.duration)m")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(red: 0.31, green: 0.28, blue: 0.95))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(s.subject)
                                    .font(.subheadline.weight(.medium))
                                if !s.notes.isEmpty {
                                    Text(s.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .navigationTitle("Study")
            .sheet(isPresented: $showLog) {
                NavigationStack {
                    Form {
                        TextField("Subject", text: $newSubject)
                        Stepper("Duration: \(newDuration) min", value: $newDuration, in: 5...300, step: 5)
                        TextField("Notes (optional)", text: $newNotes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .navigationTitle("Log Session")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showLog = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Log") {
                                guard !newSubject.isEmpty else { return }
                                store.sessions.insert(StudySession(subject: newSubject, duration: newDuration, notes: newNotes), at: 0)
                                newSubject = ""; newDuration = 25; newNotes = ""
                                showLog = false
                            }
                            .disabled(newSubject.isEmpty)
                        }
                    }
                }
            }
        }
    }
}

struct PomodoroCard: View {
    @EnvironmentObject var store: PlannerStore

    var progress: Double {
        let total = store.pomMode == .work ? 25.0 * 60 : 5.0 * 60
        return 1.0 - Double(store.pomSecondsLeft) / total
    }

    var accentColor: Color { store.pomMode == .work ? Color(red: 0.31, green: 0.28, blue: 0.95) : .green }

    var body: some View {
        VStack(spacing: 20) {
            // Mode toggle
            HStack {
                ForEach([PlannerStore.PomMode.work, .shortBreak], id: \.self) { mode in
                    Button {
                        store.switchPomMode(mode)
                    } label: {
                        Text(mode == .work ? "Focus (25m)" : "Break (5m)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(store.pomMode == mode ? accentColor.opacity(0.12) : Color.clear)
                            .foregroundStyle(store.pomMode == mode ? accentColor : .secondary)
                            .cornerRadius(8)
                    }
                }
            }

            // Circular timer
            ZStack {
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 8)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 4) {
                    Text(formatSeconds(store.pomSecondsLeft))
                        .font(.system(size: 44, weight: .light, design: .rounded))
                        .monospacedDigit()
                    Text(store.pomMode == .work ? "focus" : "break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Controls
            HStack(spacing: 16) {
                Button {
                    store.resetPomodoro()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.secondary)
                        .cornerRadius(12)
                }

                Button {
                    store.togglePomodoro()
                } label: {
                    Image(systemName: store.pomRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 80, height: 48)
                        .background(accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}

// MARK: - Habits View

struct HabitsView: View {
    @EnvironmentObject var store: PlannerStore
    @State private var showAddHabit = false
    @State private var showAddGoal = false
    @State private var newHabitName = ""
    @State private var newGoalTitle = ""
    @State private var newGoalDeadline = Date()

    var completionRatio: Double {
        guard !store.habits.isEmpty else { return 0 }
        return Double(store.habits.filter { $0.completedToday }.count) / Double(store.habits.count)
    }

    var body: some View {
        NavigationStack {
            List {
                // Completion banner
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Today's completion")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(completionRatio * 100))%")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color(red: 0.31, green: 0.28, blue: 0.95))
                        }
                        ProgressView(value: completionRatio)
                            .tint(Color(red: 0.31, green: 0.28, blue: 0.95))
                        Text("\(store.habits.filter { $0.completedToday }.count) of \(store.habits.count) habits completed")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }

                // Habits
                Section {
                    ForEach($store.habits) { $habit in
                        HStack(spacing: 14) {
                            Button {
                                habit.completedToday.toggle()
                                habit.streak += habit.completedToday ? 1 : -1
                                if habit.streak < 0 { habit.streak = 0 }
                            } label: {
                                Image(systemName: habit.completedToday ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(habit.completedToday ? Color(red: 0.31, green: 0.28, blue: 0.95) : .secondary)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(habit.name)
                                    .font(.subheadline.weight(.medium))
                                HStack(spacing: 4) {
                                    if habit.streak > 0 {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.orange)
                                        Text("\(habit.streak) day streak")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Start your streak today")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { store.habits.remove(atOffsets: $0) }
                } header: {
                    HStack {
                        Text("Daily habits")
                        Spacer()
                        Button {
                            showAddHabit = true
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }

                // Goals
                Section {
                    ForEach($store.goals) { $goal in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(goal.title)
                                    .font(.subheadline.weight(.medium))
                                    .opacity(goal.progress >= 1 ? 0.55 : 1)
                                Spacer()
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(goal.progress >= 1 ? .green : Color(red: 0.31, green: 0.28, blue: 0.95))
                            }
                            ProgressView(value: goal.progress)
                                .tint(goal.progress >= 1 ? .green : Color(red: 0.31, green: 0.28, blue: 0.95))
                            HStack {
                                Text("Due \(goal.deadline, format: .dateTime.month(.abbreviated).day())")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                // Progress stepper buttons
                                HStack(spacing: 6) {
                                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { v in
                                        Button {
                                            goal.progress = v
                                        } label: {
                                            Text("\(Int(v * 100))%")
                                                .font(.system(size: 10, weight: .semibold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(goal.progress >= v ? (goal.progress >= 1 ? Color.green : Color(red: 0.31, green: 0.28, blue: 0.95)) : Color(.systemFill))
                                                .foregroundStyle(goal.progress >= v ? .white : .secondary)
                                                .cornerRadius(5)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { store.goals.remove(atOffsets: $0) }
                } header: {
                    HStack {
                        Text("Goals")
                        Spacer()
                        Button {
                            showAddGoal = true
                        } label: {
                            Label("Add", systemImage: "plus")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Habits & Goals")
            .sheet(isPresented: $showAddHabit) {
                NavigationStack {
                    Form {
                        TextField("Habit name", text: $newHabitName)
                    }
                    .navigationTitle("New Habit")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddHabit = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                guard !newHabitName.isEmpty else { return }
                                store.habits.append(Habit(name: newHabitName, streak: 0, completedToday: false))
                                newHabitName = ""
                                showAddHabit = false
                            }
                            .disabled(newHabitName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(200)])
            }
            .sheet(isPresented: $showAddGoal) {
                NavigationStack {
                    Form {
                        TextField("Goal title", text: $newGoalTitle)
                        DatePicker("Deadline", selection: $newGoalDeadline, displayedComponents: .date)
                    }
                    .navigationTitle("New Goal")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAddGoal = false } }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                guard !newGoalTitle.isEmpty else { return }
                                store.goals.append(Goal(title: newGoalTitle, deadline: newGoalDeadline, progress: 0))
                                newGoalTitle = ""
                                showAddGoal = false
                            }
                            .disabled(newGoalTitle.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(240)])
            }
        }
    }
}
