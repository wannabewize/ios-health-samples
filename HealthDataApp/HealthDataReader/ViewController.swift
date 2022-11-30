//
//  ViewController.swift
//  HealthDataReader
//
//  Created by Jaehoon Lee on 2022/11/30.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    var healthStore: HKHealthStore = HKHealthStore()
    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateFormat = "YYYY.MM.dd HH:mm"
        formatter.locale = NSLocale.current
        
        guard HKHealthStore.isHealthDataAvailable() else {
            fatalError("Health data is not available")
        }
        
        let drinkType = HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)!
        let stepCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let heartRateType = HKSampleType.quantityType(forIdentifier: .heartRate)
        let readingType = Set([stepCountType, drinkType])
        healthStore.requestAuthorization(toShare: readingType, read: readingType) { authorized, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
//            self.resolveSampleQuery(type: stepCountType)
//            self.resolveStaticsQuery(type: stepCountType)
            self.resolveStaticsCollectionQuery(type: drinkType)
        }
    }
    
    @IBAction func addDrinkData(_ sender: Any) {
        let type = HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages)!
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: 1)
        let data = HKQuantitySample(type: type, quantity: quantity, start: Date(), end: Date())
        healthStore.save(data) { success, error in
            guard error == nil else {
                print("Error :", error!.localizedDescription)
                return
            }
            debugPrint("save data :", success)
        }
    }
    
    func resolveStaticsCollectionQuery(type: HKQuantityType) {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startOfToday)!
        let startDate = Calendar.current.date(byAdding: .day, value: -8, to: startOfToday)!
//        let startDate = Calendar.current.startOfDay(for: endDate)
        
        print("\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))")
        let interval = DateComponents(second: 10)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil)
        let options = HKStatisticsOptions.cumulativeSum
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate, options: options, anchorDate: startDate, intervalComponents: interval)
        query.initialResultsHandler = { query, collection, error in
            guard error == nil else {
                print("Error :", error!.localizedDescription)
                return
            }
            
            let statics = collection?.statistics()
            statics?.forEach({ statics in
                let sum = statics.sumQuantity()?.doubleValue(for: HKUnit.count())
                print("\(self.formatter.string(from: statics.startDate)) ~ \(self.formatter.string(from: statics.endDate)) - sum : \(sum)")
            })
        }
        query.statisticsUpdateHandler = { query, statics, collection, error in
            debugPrint("statisticsUpdateHandler works")
            if let statics = statics {
                let sum = statics.sumQuantity()!.doubleValue(for: HKUnit.count())
                print("updated : \(self.formatter.string(from: statics.startDate)) ~ \(self.formatter.string(from: statics.endDate)) - sum : \(sum)")
            }
            else {
                print("static is nil")
            }
        }
        healthStore.execute(query)

    }
    
    func resolveStaticsQuery(type: HKQuantityType) {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .second, value: -1, to: startOfToday)!
        let startDate = Calendar.current.startOfDay(for: endDate)
        
        print("\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))")

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let options = HKStatisticsOptions.cumulativeSum
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { query, statics, error in
            guard error == nil else {
                print("Error :", error!.localizedDescription)
                return
            }
            let sum = statics!.sumQuantity()!.doubleValue(for: HKUnit.count())
            print("statics :", sum)
        }
        healthStore.execute(query)
    }
    
    func resolveSampleQuery(type: HKSampleType) {
        // 1일치
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .second, value: -1, to: startOfToday)!
        let startDate = Calendar.current.startOfDay(for: endDate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        print("\(formatter.string(from: startDate)) ~ \(formatter.string(from: endDate))")
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: []) { query, results, error in
            guard error == nil else {
                print("Error :", error!.localizedDescription)
                return
            }
            let samples = results as! [HKQuantitySample]
            print("samples :", samples)
            let unit = HKUnit.count()
            samples.forEach { sample in
                let quantity = sample.quantity.doubleValue(for: unit)
                debugPrint(self.formatter.string(from: sample.startDate), self.formatter.string(from: sample.endDate), quantity)
            }
        }
        healthStore.execute(query)
    }
}

