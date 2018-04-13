//
//  ViewController.swift
//  Carry Check
//
//  Created by User on 3/25/18.
//  Copyright © 2018 dsmith. All rights reserved.
//

import UIKit

struct Result: Decodable {
    let opponents: [String]
    let numCategories: Int
    let judgements: [String: [String]]
    let time: Date
    let won: Bool
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var resultsView: UITableView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var goButton: UIButton!
    @IBOutlet var spinner: UIActivityIndicatorView!

    var results: [Result] = [] {
        didSet {
            print(results)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = results[section]
        return result.opponents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath) as! ResultCell
        cell.initialize(results[indexPath.section], indexPath)
        return cell
    }

    let formatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(formatter.string(from: results[section].time)): \((results[section].won) ? "Victory" : "Defeat")"
    }

//    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        return String.init(format: "Confidence: %0.2f%%", results[section].confidence * 100)
//    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = self.results[indexPath.section]
        guard indexPath.item < result.opponents.count else {
            return
        }

        self.searchField.text = result.opponents[indexPath.item]
        self.onGoPressed(self.goButton)
        self.resultsView.deselectRow(at: indexPath, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onGoPressed(_ sender: UIButton) {
        let url = URL.init(string: "http://127.0.0.1:3002/search/\(searchField.text!)")!
        let task = URLSession.shared.dataTask(with: url, completionHandler: { data, resp, err in
            defer {
                DispatchQueue.main.async {
                    self.spinner.stopAnimating()
                    self.resultsView.reloadData()
                }
            }
            if let err = err {
                print(err.localizedDescription)
                self.results = []
                return
            }
            guard let data = data else {
                self.results = []
                return
            }
            let decoder = JSONDecoder.init()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self.results = try! decoder.decode([Result].self, from: data)
        })
        self.spinner.startAnimating()
        self.results = []
        self.resultsView.reloadData()
        task.resume()
    }

}

class ResultCell: UITableViewCell {
    @IBOutlet var gamertagLabel: UILabel!
    @IBOutlet var confidenceLabel: UILabel!

    func initialize(_ result: Result, _ position: IndexPath) {
        let gamertag = result.opponents[position.item]
        let confidence = Double((result.judgements[gamertag] ?? []).count) / Double(result.numCategories)
        self.gamertagLabel.text = gamertag
        self.confidenceLabel.text = String.init(format: "%0.2f%%", confidence * 100)
        self.confidenceLabel.textColor = (confidence < 0.5) ? .green : .red
    }
}
