import 'package:flutter/material.dart';

class TicketData {
  final String startTicket;
  final String endTicket;
  final String amount;
  final String total;
  final String date;

  TicketData({
    required this.startTicket,
    required this.endTicket,
    required this.amount,
    required this.total,
    required this.date,
  });

  factory TicketData.fromJson(Map<String, dynamic> json) {
    return TicketData(
      startTicket: json['startTicket'],
      endTicket: json['endTicket'],
      amount: json['amount'],
      total: json['total'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTicket': startTicket,
      'endTicket': endTicket,
      'amount': amount,
      'total': total,
      'date': date,
    };
  }
}

void hideKeyboard(context) => FocusScope.of(context).requestFocus(FocusNode());
