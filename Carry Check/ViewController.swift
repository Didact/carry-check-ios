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

    var task: URLSessionTask?
    var shouldKeepAnimating = false

    @IBAction func onGoPressed(_ sender: UIButton) {
        task?.cancel()
        let url = URL.init(string: "http://24.251.154.201:10302/search/\(searchField.text!)/stream")!

        let decoder = JSONDecoder.init()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var buffer = Data()

        class Delegate: NSObject, URLSessionDataDelegate {
            let completion: (Error?) -> Void
            let received: (Data) -> Void
            init(completion: @escaping (Error?) -> Void, received: @escaping (Data) -> Void) {
                self.completion = completion
                self.received = received
            }
            func urlSession(_ session: URLSession,
                            dataTask: URLSessionDataTask,
                            didReceive data: Data) {
                self.received(data)
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                self.completion(error)
            }
        }

        let received = { (data: Data) -> Void in
            buffer += data
            let parts = buffer.split(separator: UInt8("`".utf8CString[0]), maxSplits: .max, omittingEmptySubsequences: false)
            buffer = parts.last!
            for part in parts.dropLast() {
                let result = try! decoder.decode(Result.self, from: part)
                self.results.append(result)
            }
            DispatchQueue.main.async {
                self.resultsView.reloadData()
            }
        }

        let delegate = Delegate(completion: { _ in
            DispatchQueue.main.async {
                if !self.shouldKeepAnimating {
                    self.spinner.stopAnimating()
                }
                self.shouldKeepAnimating = false
            }
        }, received: received)

        let session = URLSession.init(configuration: .default, delegate: delegate, delegateQueue: nil)
        task = session.dataTask(with: url)
        DispatchQueue.main.async {
            self.spinner.startAnimating()
            self.shouldKeepAnimating = true
        }
        self.results = []
        self.resultsView.reloadData()
        task?.resume()

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
