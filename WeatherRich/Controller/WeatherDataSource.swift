import UIKit

class WeatherDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    private enum Constants {
        static let cellReuseIdentifier = "WeatherDataCell"
    }
    var rows = [[String: String]]()

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellReuseIdentifier) {
            cell.textLabel?.text = rows[indexPath.row]["key"]
            cell.detailTextLabel?.text = rows[indexPath.row]["value"]
            return cell
        }
        assertionFailure("Cell could not be initialized.!")
        return UITableViewCell()
    }

    private func shortTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from:date)
    }
}
