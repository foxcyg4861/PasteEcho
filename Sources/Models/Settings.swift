import Foundation

struct Settings: Codable, Sendable {
    var maxItemCount: Int = 200
    var retentionPeriod: RetentionPeriod = .threeDays
    var launchAtLogin: Bool = true
    var windowMode: WindowMode = .topDocked
}

enum WindowMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case topDocked
    case freeWindow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .topDocked:  return "Top Docked"
        case .freeWindow: return "Free Window"
        }
    }
}

enum RetentionPeriod: String, Codable, CaseIterable, Identifiable, Sendable {
    case oneDay
    case threeDays
    case fiveDays

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneDay:   return "1 Day"
        case .threeDays: return "3 Days"
        case .fiveDays:  return "5 Days"
        }
    }

    var days: Int {
        switch self {
        case .oneDay:   return 1
        case .threeDays: return 3
        case .fiveDays:  return 5
        }
    }

    var cutoffDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}
