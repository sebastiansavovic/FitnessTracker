//
//  RecentActivityChart.swift
//  SS Fitness Tracker
//
//  Created by Sebastian Savovic on 2/22/21.
//

import Foundation
import UIKit
import Charts

class RecentActivityChart : UIView {
    @Dependency(DataRepository.self)var dataRepository:DataRepository
    @IBInspectable var numberOfDays:Int = -1
    
   
    lazy var chartView: LineChartView = {
       let chart = LineChartView()
        chart.frame = .zero
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.noDataText = "No recent activity found"
        chart.rightAxis.enabled = false
        chart.backgroundColor = .lightBlue
        let constraints = self.constraintsForAnchoringTo(boundsOf: chart)
        
        let yAxis = chart.leftAxis
        yAxis.labelTextColor = .white
        yAxis.labelFont = .boldSystemFont(ofSize: 12)
        
        let xAxis = chart.xAxis
        
        xAxis.valueFormatter = DayAxisValueFormatter(chart: chart)
        xAxis.labelPosition = .bottom
        xAxis.setLabelCount(7, force: false)
        xAxis.labelTextColor = .white
        xAxis.labelFont = .boldSystemFont(ofSize: 12)
        addSubview(chart)
        NSLayoutConstraint.activate(constraints)
        chart.chartDescription?.text = "Recent Activity"
        return chart
    }()
    //LineChartView, ChartViewDelegate
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    required init?(coder: NSCoder){
        super.init(coder: coder)

        self.initialize()
    }
    func initialize(){
      
       
    }
    
    func setChart(dataPoints: [Event]) {
        var calorieDataSet: [ChartDataEntry] = []
        var minutesActiveSet: [ChartDataEntry] = []
        var numberOfActiveSet: [ChartDataEntry] = []
                
        for i in 0..<dataPoints.count {
            let x = Double(dataPoints[i].eventDate.getDaysSince2021())
            let count = Double(dataPoints[i].activities?.count ?? 0)
           
            calorieDataSet.append(ChartDataEntry(x: x, y: Double(dataPoints[i].caloriesBurned), data: dataPoints[i]))
            minutesActiveSet.append(ChartDataEntry(x: x, y: Double(dataPoints[i].durationInMinutes), data: dataPoints[i]))
            numberOfActiveSet.append(ChartDataEntry(x: x, y: count))
        }
        let caloriesDataSet = self.getDataSetFromData(entries: calorieDataSet, name: "Calories Burned", color: .caloriesLine)
        let minutesActiveDataSet = self.getDataSetFromData(entries: minutesActiveSet, name: "Minutes Active", color: .minutesActive)
        let numberOfAcvitiesDataSet = self.getDataSetFromData(entries: numberOfActiveSet, name: "Number of Activities", color: .numberOfActivities)
        let data:LineChartData = LineChartData(dataSets: [caloriesDataSet, minutesActiveDataSet, numberOfAcvitiesDataSet])
        data.setDrawValues(false)
        chartView.data = data
//        chartView.setNeedsDisplay()
    }
    private func getDataSetFromData(entries: [ChartDataEntry], name: String, color: UIColor) -> LineChartDataSet {
        let chartDataSet = LineChartDataSet(entries: entries, label: name)
       
        chartDataSet.mode = .stepped
        chartDataSet.lineWidth = 3
        chartDataSet.setColor(color)
        chartDataSet.drawCirclesEnabled = false
        return chartDataSet
        
    }
    
}
