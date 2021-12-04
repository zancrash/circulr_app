import 'dart:convert';
import 'dart:async';
import 'dart:developer';

import '../services/checkOverdueItems.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:circulr_app/styles.dart';
import 'package:http/http.dart' as http;

class UserInvoices extends StatefulWidget {
  const UserInvoices({Key? key}) : super(key: key);

  @override
  _UserInvoicesState createState() => _UserInvoicesState();
}

class _UserInvoicesState extends State<UserInvoices> {
  // Map<String, dynamic>? paymentIntentData;

  // move to services file in production...
  // Future<void> makePayment() async {
  //   final url = Uri.parse(
  //       'https://us-central1-circulr-fb9b9.cloudfunctions.net/stripePayment');

  //   final response =
  //       await http.get(url, headers: {'Content-Type': 'application/json'});

  //   paymentIntentData = json.decode(response.body);

  //   await Stripe.instance.initPaymentSheet(
  //       paymentSheetParameters: SetupPaymentSheetParameters(
  //           paymentIntentClientSecret: paymentIntentData!['paymentIntent'],
  //           applePay: true,
  //           googlePay: true,
  //           // confirmPayment: true,
  //           style: ThemeMode.dark,
  //           merchantCountryCode: 'CA',
  //           merchantDisplayName: 'Circulr'));
  //   setState(() {});

  //   displayPaymentSheet();
  // }

  // Future<void> displayPaymentSheet() async {
  //   try {
  //     await Stripe.instance.presentPaymentSheet();
  //     setState(() {
  //       paymentIntentData = null;
  //     });
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text('Invoice cleared.')));
  //     clearInvoice();
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  Future<void> initPaymentSheet(context, {required int amount}) async {
    // Navigator.pop(context);
    try {
      // 1. create payment intent on the server
      final response = await http.post(
          Uri.parse(
              'https://us-central1-circulr-fb9b9.cloudfunctions.net/stripePayment'),
          body: {
            'amount': amount.toString(),
          });

      final jsonResponse = jsonDecode(response.body);
      log(jsonResponse.toString());

      //2. initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['paymentIntent'],
          merchantDisplayName: 'Flutter Stripe Store Demo',
          customerId: jsonResponse['customer'],
          customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
          style: ThemeMode.light,
          testEnv: true,
          merchantCountryCode: 'SG',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      clearInvoice();
      invoicePaidDialogue();

      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Payment completed!')),
      // );
    } catch (e) {
      if (e is StripeException) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error from Stripe: ${e.error.localizedMessage}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> invoicePaidDialogue() async {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Invoice Cleared'),
        content: const Text('Invoice has been sucessfully paid. Thank you.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'Done');
              Navigator.pop(context);
            },
            child: const Text('Done'),
            style:
                TextButton.styleFrom(primary: cBeige, backgroundColor: cBlue),
          ),
        ],
      ),
    );
  }

  Future<void>? clearInvoice() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    var collection = _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('invoices')
        .doc(selectedInvoice);
    // var snapshot =
    //     await collection.where('issued', isEqualTo: invoiceDate).get();
    // await snapshot.docs.first.reference.delete();
    collection.delete();

    // sendEmail(name: 'Circulr', email: user?.providerData[0].email.toString(), subject: subject, message: message)
  }

  DateTime? invoiceDate;
  String? selectedInvoice;

  final Stream<QuerySnapshot> _overdueStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('invoices')
      .snapshots();

  void timeTest() async {
    print('test');
  }

  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer =
        Timer.periodic(Duration(seconds: 30), (Timer t) => checkOverdueItems());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Container();
    return StreamBuilder<QuerySnapshot>(
        stream: _overdueStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('No Overdue items.');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            // print('loading');
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            shrinkWrap: true,
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return ExpansionTile(
                title: Text(data['brand']),
                subtitle: Text('Issued: ' + data['issued'].toDate().toString()),
                children: <Widget>[
                  Row(
                    children: [
                      SizedBox(width: 15),
                      TextButton(
                        onPressed: () {
                          // openMap(data['address'].toString());
                          initPaymentSheet(context,
                              amount: data['amount due'].toInt());
                        },
                        child: Text('Pay Invoice: \$' +
                            (data['amount due'].toDouble() / 100).toString()),
                        style: TextButton.styleFrom(
                            primary: cBeige, backgroundColor: primary),
                      ),
                    ],
                  )
                ],
              );

              // return ListTile(
              //     title: Text(data['brand']),
              //     subtitle:
              //         Text('Issued: ' + data['issued'].toDate().toString()),
              //     onTap: () async {
              //       // invoiceDate = data['issued'].toDate();
              //       print(document.id);
              //       selectedInvoice = document.id;
              //       makePayment();
              //       // DateTime returnDate = DateTime.now();

              //       // print('Selected: ' +
              //       //     data['name'] +
              //       //     ' ' +
              //       //     data['address'].toString());
              //     });
            }).toList(),
          );
        });
  }
}
