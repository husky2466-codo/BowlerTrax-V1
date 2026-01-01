//
//  SessionCard.swift
//  BowlerTrax
//
//  List item component for displaying session summaries.
//  Shows thumbnail, center name, shot count, and date.
//

import SwiftUI

// MARK: - Session Data Protocol

/// Protocol for session data display
protocol SessionDisplayable {
    var id: UUID { get }
    var centerName: String? { get }
    var shotCount: Int { get }
    var date: Date { get }
    var averageSpeed: Double? { get }
    var strikeRate: Double? { get }
}

// MARK: - Session Card Component

struct SessionCard<Session: SessionDisplayable>: View {
    // MARK: - Properties

    let session: Session
    let onTap: () -> Void

    // MARK: - Formatters

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    private var formattedDate: String {
        Self.dateFormatter.string(from: session.date)
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: BTSpacing.lg) {
                // Thumbnail
                thumbnailView

                // Content
                contentView

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.btTextMuted)
            }
            .padding(BTLayout.listItemPadding)
            .background(Color.btSurface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.btSurfaceElevated)
                .frame(width: 60, height: 60)

            Image(systemName: "figure.bowling")
                .font(.system(size: 24))
                .foregroundColor(.btPrimary)
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: BTSpacing.xs) {
            // Title
            Text(session.centerName ?? "Practice Session")
                .font(BTFont.h4())
                .foregroundColor(.btTextPrimary)
                .lineLimit(1)

            // Meta info row
            HStack(spacing: BTSpacing.md) {
                Label("\(session.shotCount) shots", systemImage: "circle.fill")
                Label(formattedDate, systemImage: "calendar")
            }
            .font(BTFont.caption())
            .foregroundColor(.btTextMuted)

            // Stats row (if available)
            if session.averageSpeed != nil || session.strikeRate != nil {
                HStack(spacing: BTSpacing.md) {
                    if let speed = session.averageSpeed {
                        StatBadge(value: String(format: "%.1f", speed), unit: "mph", color: .btSpeed)
                    }
                    if let strikeRate = session.strikeRate {
                        StatBadge(value: String(format: "%.0f", strikeRate), unit: "%", color: .btStrike)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(BTFont.labelSmall())
                .foregroundColor(.btTextPrimary)

            Text(unit)
                .font(BTFont.captionSmall())
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview Support

struct PreviewSession: SessionDisplayable {
    let id: UUID
    let centerName: String?
    let shotCount: Int
    let date: Date
    let averageSpeed: Double?
    let strikeRate: Double?
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil

    var body: some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.btTextMuted)

            VStack(spacing: BTSpacing.xs) {
                Text(title)
                    .font(BTFont.h3())
                    .foregroundColor(.btTextPrimary)

                Text(message)
                    .font(BTFont.body())
                    .foregroundColor(.btTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionTitle = actionTitle {
                BTActionButton.primary(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(BTSpacing.xxl)
        .frame(maxWidth: .infinity)
        .background(Color.btSurface)
        .cornerRadius(BTLayout.cardCornerRadius)
    }
}

// MARK: - Preview

#Preview("Session Cards") {
    ScrollView {
        VStack(spacing: BTSpacing.md) {
            // Session with stats
            SessionCard(
                session: PreviewSession(
                    id: UUID(),
                    centerName: "Bowlero Lanes",
                    shotCount: 45,
                    date: Date(),
                    averageSpeed: 17.2,
                    strikeRate: 47
                )
            ) {}

            // Session without stats
            SessionCard(
                session: PreviewSession(
                    id: UUID(),
                    centerName: "Practice at Home",
                    shotCount: 12,
                    date: Date().addingTimeInterval(-86400),
                    averageSpeed: nil,
                    strikeRate: nil
                )
            ) {}

            // Session with no center name
            SessionCard(
                session: PreviewSession(
                    id: UUID(),
                    centerName: nil,
                    shotCount: 30,
                    date: Date().addingTimeInterval(-172800),
                    averageSpeed: 16.8,
                    strikeRate: 35
                )
            ) {}

            // Empty state
            EmptyStateCard(
                icon: "figure.bowling",
                title: "No sessions yet",
                message: "Start your first session to see your stats here",
                action: {},
                actionTitle: "New Session"
            )
        }
        .padding(BTLayout.screenHorizontalPadding)
    }
    .background(Color.btBackground)
}
