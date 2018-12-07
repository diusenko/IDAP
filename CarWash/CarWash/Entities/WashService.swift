//
//  WashServise.swift
//  CarWash
//
//  Created by Student on 10/25/18.
//  Copyright © 2018 Student. All rights reserved.
//

import Foundation

class WashService: StateObserver {
    
    private let accountant: Accountant
    private let director: Director
    let id: Int
    private let washers: Atomic<[Washer]>
    private let cars = Queue<Car>()
    
    init(
        id: Int,
        accountant: Accountant,
        director: Director,
        washers: [Washer]
    ) {
        self.id = id
        self.accountant = accountant
        self.washers = Atomic(washers)
        self.director = director
        self.washers.value.forEach { washer in
            washer.add(observer: self)
        }
        self.accountant.add(observer: self)
        self.director.add(observer: self)
    }
    
    func washCar(_ car: Car) {
        self.washers.transform {
            let availableWasher = $0.first {
                $0.state == .available
            }
            
            let enqueueCar = { self.cars.enqueue(car) }
            
            if self.cars.isEmpty {
                if let availableWasher = availableWasher {
                    availableWasher.performWork(processedObject: car)
                } else {
                    enqueueCar()
                }
            } else {
                enqueueCar()
            }
        }
    }
    
    func valueChanged<ProcessObject>(
        subject: Staff<ProcessObject>,
        oldValue: Staff<ProcessObject>.State,
        newValue: Staff<ProcessObject>.State
    ) {
        if let washer = subject as? Washer  {
            if newValue == .available {
                self.cars.dequeue().do(washer.performWork)
            } else if newValue == .waitForProcessing {
                self.accountant.performWork(processedObject: washer)
            }
        } else if let accountant = subject as? Accountant {
            if newValue == .waitForProcessing {
                self.director.performWork(processedObject: accountant)
            }
        }
    }
}
