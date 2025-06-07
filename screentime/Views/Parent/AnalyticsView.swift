import SwiftUI
import Charts

struct AnalyticsView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - State
    @FetchRequest(
        entity: User.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        predicate: NSPredicate(format: "userType == %@", Profile.UserType.child.rawValue)
    ) var children: FetchedResults<User>
    
    @State private var selectedChild: User?
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Child Picker
            if !children.isEmpty {
                Picker("Select Child", selection: $selectedChild) {
                    Text("All Children").tag(nil as User?)
                    ForEach(children, id: \.objectID) { child in
                        Text(child.name).tag(child as User?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            
            // Timeframe Picker
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases) { timeframe in
                    Text(timeframe.title).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Screen Time Usage Chart
                    ChartCard(title: "Screen Time Usage") {
                        ScreenTimeChart(
                            data: screenTimeData,
                            timeframe: selectedTimeframe
                        )
                    }
                    
                    // Task Completion Chart
                    ChartCard(title: "Task Completion") {
                        TaskCompletionChart(
                            data: taskCompletionData,
                            timeframe: selectedTimeframe
                        )
                    }
                    
                    // App Usage Chart
                    if let child = selectedChild {
                        ChartCard(title: "App Usage") {
                            ApprovedAppsChart(
                                apps: [] // TODO: Implement approved apps fetching from Supabase
                            )
                        }
                    }
                }
                .padding()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Data
    private var screenTimeData: [ScreenTimeDataPoint] {
        // In a real app, this would fetch actual usage data
        // For demo purposes, we'll generate sample data
        selectedTimeframe.generateSampleScreenTimeData()
    }
    
    private var taskCompletionData: [TaskCompletionDataPoint] {
        // In a real app, this would fetch actual task completion data
        // For demo purposes, we'll generate sample data
        selectedTimeframe.generateSampleTaskCompletionData()
    }
}

// MARK: - Chart Card
struct ChartCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 5)
            
            content()
                .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - Screen Time Chart
struct ScreenTimeChart: View {
    let data: [ScreenTimeDataPoint]
    let timeframe: Timeframe
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(Color.accentColor)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: timeframe.strideBy)) { value in
                AxisGridLine()
                AxisValueLabel(format: timeframe.dateFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - Task Completion Chart
struct TaskCompletionChart: View {
    let data: [TaskCompletionDataPoint]
    let timeframe: Timeframe
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Completed", point.completed)
                )
                .foregroundStyle(Color.green)
                
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Total", point.total)
                )
                .foregroundStyle(Color.gray.opacity(0.5))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: timeframe.strideBy)) { value in
                AxisGridLine()
                AxisValueLabel(format: timeframe.dateFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - App Usage Chart
struct ApprovedAppsChart: View {
    let apps: [SupabaseApprovedApp]
    
    var body: some View {
        Chart {
            ForEach(apps) { app in
                SectorMark(
                    angle: .value("Usage", app.isEnabled ? 1 : 0),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("App", app.name))
            }
        }
    }
}

// MARK: - Data Models
struct ScreenTimeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct TaskCompletionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Int
    let total: Int
}

// MARK: - Timeframe
enum Timeframe: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
    
    var strideBy: Calendar.Component {
        switch self {
        case .day: return .hour
        case .week: return .day
        case .month: return .weekOfMonth
        }
    }
    
    var dateFormat: Date.FormatStyle {
        switch self {
        case .day:
            return .dateTime.hour()
        case .week:
            return .dateTime.weekday()
        case .month:
            return .dateTime.month()
        }
    }
    
    func generateSampleScreenTimeData() -> [ScreenTimeDataPoint] {
        // Generate sample data based on timeframe
        let calendar = Calendar.current
        let now = Date()
        var points: [ScreenTimeDataPoint] = []
        
        switch self {
        case .day:
            for hour in 0..<24 {
                if let date = calendar.date(byAdding: .hour, value: -hour, to: now) {
                    points.append(ScreenTimeDataPoint(
                        date: date,
                        minutes: Int.random(in: 0...60)
                    ))
                }
            }
        case .week:
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                    points.append(ScreenTimeDataPoint(
                        date: date,
                        minutes: Int.random(in: 0...480)
                    ))
                }
            }
        case .month:
            for week in 0..<4 {
                if let date = calendar.date(byAdding: .weekOfMonth, value: -week, to: now) {
                    points.append(ScreenTimeDataPoint(
                        date: date,
                        minutes: Int.random(in: 0...3360)
                    ))
                }
            }
        }
        
        return points.reversed()
    }
    
    func generateSampleTaskCompletionData() -> [TaskCompletionDataPoint] {
        // Generate sample data based on timeframe
        let calendar = Calendar.current
        let now = Date()
        var points: [TaskCompletionDataPoint] = []
        
        switch self {
        case .day:
            for hour in 0..<24 {
                if let date = calendar.date(byAdding: .hour, value: -hour, to: now) {
                    let total = Int.random(in: 1...5)
                    points.append(TaskCompletionDataPoint(
                        date: date,
                        completed: Int.random(in: 0...total),
                        total: total
                    ))
                }
            }
        case .week:
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -day, to: now) {
                    let total = Int.random(in: 3...8)
                    points.append(TaskCompletionDataPoint(
                        date: date,
                        completed: Int.random(in: 0...total),
                        total: total
                    ))
                }
            }
        case .month:
            for week in 0..<4 {
                if let date = calendar.date(byAdding: .weekOfMonth, value: -week, to: now) {
                    let total = Int.random(in: 15...25)
                    points.append(TaskCompletionDataPoint(
                        date: date,
                        completed: Int.random(in: 0...total),
                        total: total
                    ))
                }
            }
        }
        
        return points.reversed()
    }
}

// MARK: - Preview
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsView()
        }
    }
} 