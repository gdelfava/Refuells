//
//  AnalyticsView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var selectedTimeframe = 0
    private let timeframes = ["Week", "Month", "Year"]
    
        var body: some View {
        MenuWrapperView {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Timeframe picker
                        HStack {
                            Spacer()
                            
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(0..<timeframes.count, id: \.self) { index in
                                    Text(timeframes[index]).tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        .padding(.horizontal)
                        
                        // Summary cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            AnalyticsCard(
                                title: "Total Spent",
                                value: "$248.00",
                                change: "+12.5%",
                                isPositive: true,
                                icon: "dollarsign.circle.fill",
                                color: .green
                            )
                            
                            AnalyticsCard(
                                title: "Fuel Efficiency",
                                value: "8.2L/100km",
                                change: "-5.2%",
                                isPositive: true,
                                icon: "speedometer",
                                color: .blue
                            )
                            
                            AnalyticsCard(
                                title: "Total Distance",
                                value: "1,234km",
                                change: "+8.7%",
                                isPositive: true,
                                icon: "location.fill",
                                color: .purple
                            )
                            
                            AnalyticsCard(
                                title: "Avg. Cost/Liter",
                                value: "$1.98",
                                change: "+2.1%",
                                isPositive: false,
                                icon: "fuelpump.fill",
                                color: .orange
                            )
                        }
                        .padding(.horizontal)
                        
                        // Chart section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Fuel Consumption Trend")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            ChartView()
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                        
                        // Efficiency breakdown
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Efficiency Breakdown")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                EfficiencyRow(
                                    category: "Highway Driving",
                                    percentage: 75,
                                    efficiency: "6.8L/100km",
                                    color: .green
                                )
                                
                                EfficiencyRow(
                                    category: "City Driving",
                                    percentage: 25,
                                    efficiency: "10.2L/100km",
                                    color: .orange
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Drive")
                .navigationBarTitleDisplayMode(.large)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add new analytics entry or report
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                )
            }
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isPositive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ChartView: View {
    var body: some View {
        VStack {
            // Simple chart representation
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 30, height: CGFloat.random(in: 50...150))
                        
                        Text("D\(index + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top)
            
            Text("Daily Fuel Consumption (L)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EfficiencyRow: View {
    let category: String
    let percentage: Int
    let efficiency: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            HStack {
                ProgressView(value: Double(percentage), total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                
                Text(efficiency)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    AnalyticsView()
} 