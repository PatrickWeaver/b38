//
//  ViewController.swift
//  B38
//
//  Created by Patrick Weaver on 7/28/18.
//  Copyright © 2018 Patrick Weaver. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incomingBusses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "busCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0;
        cell.textLabel?.lineBreakMode = .byWordWrapping
        let cellBus = incomingBusses[indexPath.row]
        
        var destinationName = ""
        if let destination = cellBus.destinationName {
            destinationName = "\(destination)\n"
        }
        
        var milesAway = ""
        if let miles = cellBus.milesAway,cellBus.descriptiveDistance.range(of: "miles") == nil {
            milesAway = "\(((miles * 10).rounded(.up)/10)) miles away\n"
        }
        
        var stopsAway = ""
        if let stops = cellBus.stopsAway {
            stopsAway = "\(stops) stops away\n"
        }
        
        
        cell.textLabel?.text = "\(destinationName)\(cellBus.descriptiveDistance)\n\(milesAway)\(stopsAway)\(cellBus.arrivalCountdown)"
        return cell
    }

    @IBOutlet weak var busNumber: UILabel!
    @IBOutlet weak var intersection: UILabel!
    @IBOutlet weak var nextBussesTable: UITableView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var loadingMessage: UILabel!
    
    @IBAction func refreshButtonAction(_ sender: UIButton) {
        refresh()
    }
    
    var incomingBusses = [Bus]()
    
    var isTimerRunning = false
    func runBusCountdownTimer() {
        if (!isTimerRunning){
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                self.updateTimer()
            })
            //Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(ViewController.updateTimer)), userInfo: nil, repeats: true)
            isTimerRunning = true
        }
    }
    
    func updateTimer() {
        
        var newIncomingBusses = [Bus]()
        
        for var bus in incomingBusses {
            if (bus.secondsAway != nil) {
                bus.secondsAway! -= 1
            }
            newIncomingBusses.append(bus)
        }
        incomingBusses = newIncomingBusses

        nextBussesTable.reloadData()
    }
    
    func refresh() {
        refreshButton.isHidden = true
        loadingMessage.isHidden = false
        let busEndpoint = "https://mta-api.glitch.me/api/bus/B38/303092"
        guard let url = URL(string: busEndpoint) else {
            print("Error: Url Error")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            // check error
            
            guard let resData = data else {
                print("Error: data error")
                return
            }
            
            //let dataAsString = String(data: resData, encoding: .utf8)!
            //print(dataAsString)
            
            do {
                let busData = try JSONDecoder().decode(BusDataBlob.self, from: resData)
                //print("Line Ref: \(busData.jsonSiri.serviceDelivery.stopMonitoringDelivery[0].monitoredStopVisits[0].monitoredVehicleJourney.lineRef)")
                
                let incomingBussesData = busData.jsonSiri.serviceDelivery.stopMonitoringDelivery[0].monitoredStopVisits
                self.incomingBusses = [Bus]()
                for bus in incomingBussesData {
                    let journey = bus.monitoredVehicleJourney
                    let distances = journey.monitoredCall.extensions?.distances
                    let newBus = Bus(
                        id: UUID.init(),
                        descriptiveDistance: (distances?.descriptive)!,
                        metersAway: (distances?.metersAway)!,
                        stopsAway: (distances?.stopsAway)!,
                        secondsAway: journey.monitoredCall.timeUntilArrivalInSeconds,
                        destinationId: journey.destinationId,
                        destinationName: journey.destinationName
                    )
                    self.incomingBusses.append(newBus)
                }
                
                /*
                for bus in self.incomingBusses {
                    print(bus)
                    print("")
                }
                */
                DispatchQueue.main.async {
                    self.runBusCountdownTimer()
                    self.nextBussesTable.reloadData()
                    self.refreshButton.isHidden = false
                    self.loadingMessage.isHidden = true
                }
                
                
            } catch {
                print("Catch Block: \(error)")
            }
            
        }.resume()
        self.busNumber.text = "B38"
        self.intersection.text = "Willoughby Ave. and Classon Ave."
    }
}

