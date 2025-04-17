import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:ticket_collection/models/ticket_data.dart';
import 'package:ticket_collection/utils/download_report.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final startTicketController = TextEditingController();
  final endTicketController = TextEditingController();
  final amountController = TextEditingController();
  List<TicketData> savedDataList = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  bool get isEndTicketEnabled {
    return startTicketController.text.isNotEmpty;
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDate = prefs.getString('date');
    String currentDate = DateTime.now().toLocal().toString().split(' ')[0];

    if (savedDate == currentDate) {
      String? savedDataJson = prefs.getString('savedDataList');
      if (savedDataJson != null) {
        List<dynamic> jsonList = jsonDecode(savedDataJson);
        setState(() {
          savedDataList =
              jsonList.map((item) => TicketData.fromJson(item)).toList();
        });
      }
    } else {
      prefs.clear();
    }
  }

  Future<void> _saveData() async {
    if (mounted) hideKeyboard(context);

    if (!_formKey.currentState!.validate()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String startTicket = startTicketController.text;
    String endTicket = endTicketController.text;
    String amount = amountController.text;

    int start = int.tryParse(startTicket) ?? 0;
    int end = int.tryParse(endTicket) ?? 0;
    double amt = double.tryParse(amount) ?? 0.0;

    int count = (start <= end) ? (end - start) : 0;
    double total = count * amt;

    String currentDate = DateTime.now().toLocal().toString().split(' ')[0];

    TicketData data = TicketData(
      startTicket: startTicket,
      endTicket: endTicket,
      amount: amount,
      total: total.toStringAsFixed(2),
      date: currentDate,
      count: count,
    );

    String savedDataJson =
        jsonEncode(savedDataList.map((item) => item.toJson()).toList());
    await prefs.setString('savedDataList', savedDataJson);
    await prefs.setString('date', currentDate);

    startTicketController.clear();
    endTicketController.clear();
    amountController.clear();

    setState(() {
      savedDataList.add(data);
    });
  }

  Future<void> _deleteItem(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedDataList.removeAt(index);
    });
    String updatedJson =
        jsonEncode(savedDataList.map((item) => item.toJson()).toList());
    await prefs.setString('savedDataList', updatedJson);
  }

  void _clearAll(BuildContext context) async {
    bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'Are you sure you want to clear all data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        savedDataList.clear();
      });
      prefs.clear();
      startTicketController.clear();
      endTicketController.clear();
      amountController.clear();
    }
  }

  double get totalCollected {
    return savedDataList.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item.total) ?? 0.0),
    );
  }

  int get totalCount {
    return savedDataList.fold(0, (sum, item) => sum + item.count);
  }

  @override
  void dispose() {
    startTicketController.dispose();
    endTicketController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String currentFormattedDate =
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Ticket Collection',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => downloadPdf(context, savedDataList),
        child: const Icon(Icons.download),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                "Sales Data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: startTicketController,
                decoration: const InputDecoration(
                  labelText: 'Start Ticket',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onChanged: (text) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: endTicketController,
                decoration: const InputDecoration(
                  labelText: 'End Ticket',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  int start = int.tryParse(startTicketController.text) ?? 0;
                  int end = int.tryParse(value) ?? 0;
                  if (end <= start) {
                    return 'End ticket should be greater than start ticket';
                  }
                  return null;
                },
                enabled: isEndTicketEnabled,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+(\.\d{0,2})?'))
                ],
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
              if (savedDataList.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Today's Collection ($currentFormattedDate)",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _clearAll(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const <DataColumn>[
                                DataColumn(
                                    label: Text('Start',
                                        style: TextStyle(fontSize: 12))),
                                DataColumn(
                                    label: Text('End',
                                        style: TextStyle(fontSize: 12))),
                                DataColumn(
                                    label: Text('Amount',
                                        style: TextStyle(fontSize: 12))),
                                DataColumn(
                                    label: Text('Count',
                                        style: TextStyle(fontSize: 12))),
                                DataColumn(
                                    label: Text('Total',
                                        style: TextStyle(fontSize: 12))),
                              ],
                              rows: [
                                ...savedDataList.asMap().entries.map(
                                  (entry) {
                                    final ticket = entry.value;
                                    final index = entry.key;
                                    return DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text(ticket.startTicket,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                        DataCell(Text(ticket.endTicket,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                        DataCell(Text(ticket.amount,
                                            style:
                                                const TextStyle(fontSize: 12))),
                                        DataCell(Text(ticket.count.toString(),
                                            style:
                                                const TextStyle(fontSize: 12))),
                                        DataCell(Text(
                                          double.tryParse(ticket.total)
                                                      ?.remainder(1) ==
                                                  0
                                              ? double.parse(ticket.total)
                                                  .toInt()
                                                  .toString()
                                              : double.parse(ticket.total)
                                                  .toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 12),
                                        )),
                                      ],
                                      onLongPress: () =>
                                          _showDeleteDialog(index),
                                    );
                                  },
                                ),
                                DataRow(
                                  color:
                                      WidgetStateProperty.all(Colors.grey[300]),
                                  cells: <DataCell>[
                                    const DataCell(Text('Total',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                    const DataCell(Text('',
                                        style: TextStyle(fontSize: 12))),
                                    const DataCell(Text('',
                                        style: TextStyle(fontSize: 12))),
                                    DataCell(Text(totalCount.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                    DataCell(Text(
                                      totalCollected % 1 == 0
                                          ? totalCollected.toInt().toString()
                                          : totalCollected.toStringAsFixed(2),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    TicketData ticket = savedDataList[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start Ticket: ${ticket.startTicket}'),
              Text('End Ticket: ${ticket.endTicket}'),
              Text('Amount: ${ticket.amount}'),
              Text('Count: ${ticket.count}'),
              Text('Total: ${ticket.total}'),
              const SizedBox(height: 16),
              const Text('Are you sure you want to delete this entry?'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(index);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
