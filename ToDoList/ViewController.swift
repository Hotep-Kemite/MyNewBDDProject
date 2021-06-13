
import UIKit
import CoreData

class ViewController: UITableViewController {

    private var items: [Item] = []

    private var managedContext: NSManagedObjectContext {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        items = fetchItems()

        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.leftBarButtonItem = editButtonItem
    }


    @IBAction func addButtonAction(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Nouvelle tâche",
                                                message: "Ajouter une tâche à la liste",
                                                preferredStyle: .alert)

        alertController.addTextField { (textField) in
            textField.placeholder = "Description…"
        }

        let cancelButton = UIAlertAction(title: "Annuler",
                                         style: .cancel,
                                         handler: nil)

        let saveButton = UIAlertAction(title: "Ajouter",
                                       style: .default) { _ in
            guard let textField = alertController.textFields?.first else {
                return
            }

            self.createItem(title: textField.text!)
            self.items = self.fetchItems()
            self.tableView.reloadData()
        }

        alertController.addAction(saveButton)
        alertController.addAction(cancelButton)

        present(alertController, animated: true)
    }

    private func fetchItems(searchQuery: String? = nil) -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()

        let dateSortDescriptor = NSSortDescriptor(keyPath: \Item.creationDate, ascending: false)
        let titleSortDescriptor = NSSortDescriptor(keyPath: \Item.title, ascending: true)

        fetchRequest.sortDescriptors = [dateSortDescriptor, titleSortDescriptor]

        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            let predicate = NSPredicate(format: "%K contains[cd] %@",
                                        argumentArray: [#keyPath(Item.title), searchQuery])
            fetchRequest.predicate = predicate
        }

        do {
            return try self.managedContext.fetch(fetchRequest)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func createItem(title: String, date: Date = Date()) {
        let item = Item(context: managedContext)
        item.title = title
        item.creationDate = date

        saveContext()
    }

    private func saveContext() {
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        cell.accessoryType = item.isChecked ? .checkmark : .none
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: item.creationDate!,
                                                                   dateStyle: .medium,
                                                                   timeStyle: .short)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }

        let index = indexPath.row
        let item = items[index]

        managedContext.delete(item)
        saveContext()

        items.remove(at: index)

        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        items[indexPath.row].isChecked.toggle()
        saveContext()

        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        cell.accessoryType = items[indexPath.row].isChecked ? .checkmark : .none
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchQuery = searchController.searchBar.text
        items = fetchItems(searchQuery: searchQuery)
        tableView.reloadData()
    }
}
