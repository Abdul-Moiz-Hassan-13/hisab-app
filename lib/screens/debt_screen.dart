import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/debt_entry.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key, required this.initialDebts});

  final List<DebtEntry> initialDebts;

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  late final List<DebtEntry> _debts;
  String _currency = 'Rs';

  @override
  void initState() {
    super.initState();
    _debts = List<DebtEntry>.from(widget.initialDebts);
  }

  void _changeCurrency() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Rs (Rupees)'),
                leading: Radio<String>(
                  value: 'Rs',
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
              ListTile(
                title: const Text('\$ (Dollar)'),
                leading: Radio<String>(
                  value: '\$',
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
              ListTile(
                title: const Text('€ (Euro)'),
                leading: Radio<String>(
                  value: '€',
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
              ListTile(
                title: const Text('£ (Pound)'),
                leading: Radio<String>(
                  value: '£',
                  groupValue: _currency,
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                    Navigator.pop(dialogContext);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  double get _totalDebt {
    return _debts.fold(0.0, (sum, debt) => sum + debt.amount);
  }

  void _addDebt() {
    final personController = TextEditingController();
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Debt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personController,
                decoration: const InputDecoration(
                  labelText: 'Person/Entity',
                  hintText: 'To whom',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final person = personController.text.trim();
                final amount = double.tryParse(amountController.text);

                if (person.isNotEmpty && amount != null && amount > 0) {
                  setState(() {
                    _debts.add(DebtEntry(person: person, amount: amount));
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editDebt(int index) {
    final debt = _debts[index];
    final personController = TextEditingController(text: debt.person);
    final amountController = TextEditingController(text: debt.amount.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Debt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personController,
                decoration: const InputDecoration(
                  labelText: 'Person/Entity',
                  hintText: 'To whom',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final person = personController.text.trim();
                final amount = double.tryParse(amountController.text);

                if (person.isNotEmpty && amount != null && amount > 0) {
                  setState(() {
                    _debts[index] = DebtEntry(person: person, amount: amount);
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDebt(int index) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Debt'),
          content: const Text('Are you sure you want to delete this debt?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _debts.removeAt(index);
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, _debts);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debt to Pay'),
          centerTitle: true,
          leading: BackButton(onPressed: () => Navigator.pop(context, _debts)),
          actions: [
            IconButton(
              icon: const Icon(Icons.currency_exchange),
              onPressed: _changeCurrency,
              tooltip: 'Change Currency',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Debt:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_currency ${_totalDebt.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _debts.isEmpty
                  ? const Center(
                      child: Text('No debts added yet. Tap + to add.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _debts.length,
                      itemBuilder: (context, index) {
                        final debt = _debts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(debt.person),
                            subtitle: Text('$_currency ${debt.amount.toStringAsFixed(2)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editDebt(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteDebt(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addDebt,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
