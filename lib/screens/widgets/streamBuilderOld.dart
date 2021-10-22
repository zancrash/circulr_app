import 'dart:async';
// import 'dart:convert';

// import 'package:circulr_app/screens/widgets/locations.dart';
import 'package:circulr_app/screens/widgets/locationsDropdown.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_stripe/flutter_stripe.dart' hide Address;
// import 'package:mailer/mailer.dart';
// import 'package:http/http.dart' as http;
import 'locations.dart';
import 'package:flutter_spinbox/material.dart';
import '../services/addGenericReturn.dart';

class UserItems extends StatefulWidget {
  const UserItems({Key? key}) : super(key: key);

  @override
  _UserItemsState createState() => _UserItemsState();
}

class _UserItemsState extends State<UserItems> {
  // User? user = FirebaseAuth.instance.currentUser;
  final Stream<QuerySnapshot> _itemStream = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('items_purchased')
      .snapshots();

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void>? deleteItem() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    var collection = _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('items_purchased');
    var snapshot =
        await collection.where('date', isEqualTo: itemPurchased).get();
    await snapshot.docs.first.reference.delete();
  }

  String? selectedBrand;

  Future<void>? addReturned() {
    // final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User? user = FirebaseAuth.instance.currentUser;
    DateTime now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month, now.day);
    bool pastdue = false;
    CollectionReference ref = _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('items_returned');

    print('adding..');
    return ref.add({
      'brand': selectedBrand,
      'qty': _currentSliderValue.toInt(),
      'date': now,
      'past due': pastdue,
    });
  }

  addInvoice(String brand, int qty, DateTime date) async {
    // final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User? user = FirebaseAuth.instance.currentUser;
    DateTime now = new DateTime.now();
    CollectionReference ref =
        _firestore.collection('users').doc(user?.uid).collection('invoices');

    print('adding to invoices');
    // bool exists = checkInvoiceExists(date) as bool;
    bool exists = await checkInvoiceExists(date);
    print(exists);

    if (exists == false) {
      ref.add({
        'brand': brand,
        'qty': qty,
        'amount due': 0.00,
        'item purchase date': date,
        'issued': now,
      });
    } else {
      print('Invoice not issued.');
    }
  }

  Future<bool> checkInvoiceExists(DateTime date) async {
    User? user = FirebaseAuth.instance.currentUser;
    bool exists = false;

    // Query user invoices to see if invoice for product has already been issued.
    print('Checking if invoice already issued.');
    var result = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('invoices')
        .where('item purchase date', isEqualTo: date)
        .get();
    result.docs.forEach((res) {
      exists = res.exists;
    });
    return exists;
  }

  int? daysBetween(DateTime? from, DateTime to) {
    from = DateTime(from!.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  Future<void> updateUser() {
    User? user = FirebaseAuth.instance.currentUser;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users
        .doc(user?.uid)
        // .update({'past_due': true})
        .update({'overdue_items': overdueCount})
        // .update({'overdue_items': FieldValue.increment(1)})
        .then((value) => print("User Updated"))
        .catchError((error) => print("Failed to update user: $error"));
  }

  // Update user overdue items count:
  int overdueCount = 0; // varialbe to store number of overdue items
  void userPastDue() async {
    User? user = FirebaseAuth.instance.currentUser;
    DateTime x = DateTime.now().subtract(Duration(days: 30));

    int itemCount = 0;

    // query firestore for user items more than 30 days old
    var result = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('items_purchased')
        .where('date', isLessThanOrEqualTo: x)
        .get();
    result.docs.forEach((res) {
      // print(res.data());
      // print(res);
      // print(res.exists);
      // print(res.data()['date']);
      addInvoice(
          res.data()['brand'], res.data()['qty'], res.data()['date'].toDate());
      itemCount +=
          1; // for each item more than 30 days old, increment item count variable
    });
    print(itemCount);
    print('userPastDue executed.');
    overdueCount = itemCount;
    // print('count: ' + overdueCount.toString());
  }

  // Run function to decrement user's overdue items count
  Future<void> userReturnLate() async {
    User? user = FirebaseAuth.instance.currentUser;
    DateTime x = DateTime.now().subtract(Duration(days: 30));

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return users
        .doc(user?.uid)
        .update({'overdue_items': FieldValue.increment(-1)});
  }

  // function to get user's overdue count
  Future<int> getOverdues() async {
    User? user = FirebaseAuth.instance.currentUser;
    int overdueCount = 0;

    DocumentReference docRef =
        FirebaseFirestore.instance.collection('users').doc(user?.uid);

    await docRef.get().then((snapshot) {
      overdueCount = snapshot['overdue_items'];
    });

    return overdueCount;
  }

  DateTime? itemPurchased;
  double _currentSliderValue = 1;

  int overdues = 0;

  final Stream<QuerySnapshot> _locStream =
      FirebaseFirestore.instance.collection('locations').snapshots();

  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(minutes: 15), (Timer t) => userPastDue());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // void testFunc() async {
  //   setState(() {});
  //   // print('test func');
  // }

  static const TextStyle titleStyle =
      TextStyle(fontSize: 25, fontWeight: FontWeight.bold);

  var selectedLoc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _itemStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('No brands found.');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('loading');
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Center(
            child: Container(
                child: ListView(
              shrinkWrap: true,
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data()! as Map<String, dynamic>;
                return ListTile(
                    title: Text(data['qty'].toString() + 'x ' + data['brand']),
                    subtitle: Text('Qty: ' + data['qty'].toString()),
                    onTap: () async {
                      // sendEmail();
                      selectedBrand = data['brand'];
                      print('Selected: $selectedBrand');
                      // userPastDue();
                      itemPurchased = data['date'].toDate();
                      DateTime returnDate = DateTime.now();
                      final difference = daysBetween(itemPurchased, returnDate);
                      print('difference: ' + difference.toString());

                      // If item is more than 30 days old, set past due to true (does not update firestore entry)
                      // if (difference! > 30) {
                      //   data['past_due'] = true;
                      //   print('set to true');
                      //   // addInvoice();
                      //   // updateUser();
                      // } else {
                      //   data['past_due'] = false;
                      // }

                      // call getOverdues to get user's overdue items count.
                      // int overdues = await getOverdues();
                      // print('overdue count: ' + overdues.toString());

                      // showDialog(
                      //     context: context,
                      //     builder: (context) {
                      //       return Dialog(
                      //         shape: RoundedRectangleBorder(
                      //             borderRadius: BorderRadius.circular(10)),
                      //         elevation: 16,
                      //         child: Container(
                      //           child: Locations(),
                      //         ),
                      //       );
                      //     });

                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Text('How many units are you returning from ' +
                              data['brand'] +
                              '?'),
                          content:
                              StatefulBuilder(builder: (context, setState) {
                            return Container(
                              // Container(
                              //   child: Locations(),
                              // ),
                              height: 200,
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    height: 100,
                                    child: Slider(
                                      value: _currentSliderValue,
                                      min: 1,
                                      max: 10,
                                      divisions: 10,
                                      // max: data['qty'].toDouble(),
                                      // divisions: data['qty'],
                                      label: _currentSliderValue
                                          .round()
                                          .toString(),
                                      onChanged: (double value) {
                                        setState(() {
                                          _currentSliderValue = value;
                                        });
                                      },
                                    ),
                                  ),
                                  Container(
                                    height: 50,
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: _locStream,
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Text(
                                              'Error loading location data');
                                        } else {
                                          List<DropdownMenuItem> locItems = [];
                                          for (int i = 0;
                                              i < snapshot.data!.docs.length;
                                              i++) {
                                            DocumentSnapshot snap =
                                                snapshot.data!.docs[i];
                                            locItems.add(
                                              DropdownMenuItem(
                                                child: Text(
                                                  snap['name'],
                                                ),
                                                value: snap['name'],
                                              ),
                                            );
                                          }
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              DropdownButton<dynamic>(
                                                items: locItems,
                                                onChanged: (locValue) async {
                                                  // final snackBar = SnackBar(
                                                  //   content: Text('Selected Location: $locValue'),
                                                  // );
                                                  // int overdueCount =
                                                  //     await getOverdues();
                                                  print(overdueCount);
                                                  setState(() {
                                                    selectedLoc = locValue;
                                                  });
                                                  print(
                                                      'Selected Location: $selectedLoc');
                                                  // ScaffoldMessenger.showSnackBar(snackBar)
                                                },
                                                value: selectedLoc,
                                                isExpanded: false,
                                                hint:
                                                    new Text('Select Location'),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  // Locations(),
                                ],
                              ),
                            );
                          }),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                ///

                                if (data['past_due']) {
                                  // data['past_due'] = true;
                                  // Navigator.pop(context, 'Done');
                                  // addInvoice();
                                }

                                // print(data['past_due']);
                                // if (data['past_due']) {
                                //   // data['past_due'] = true;
                                //   Navigator.pop(context, 'Done');
                                //   depositAlert();
                                // } else {
                                //   addReturned();
                                //   deleteItem();
                                //   Navigator.pop(context, 'Done');
                                // }
                                // depositAlert();
                                // Navigator.pop(context, 'Done');
                                // print(_currentSliderValue.toInt());

                                // makePayment();
                                // deleteItem();
                                // Navigator.pop(context, 'Done');
                                addReturned();
                                deleteItem();
                                Navigator.pop(context, 'Done');
                              },
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      );
                      print(_currentSliderValue.toInt());

                      // print(data['name']);
                      // selectedBrand = data['name'];
                      print('Selected: ' +
                          data['brand'] +
                          ' ' +
                          data['qty'].toString());
                    });
              }).toList(),
            )),
          );
        });
  }
}