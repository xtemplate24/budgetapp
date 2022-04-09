import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/firebase_interactions/firebase_interactions.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:budgetapp/screens/setCategory/set_category_page.dart';
import 'package:budgetapp/screens/setIncome/set_income_page.dart';
import 'package:budgetapp/screens/setup/setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomePageState extends State<HomePage> {
  bool dataRetrieved = false;
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  List<Map> categories = [];
  List<String> categoryList = [];
  List<Map> transactions = [];
  DocumentReference? userDocument;
  CollectionReference? userCategoryRef;
  CollectionReference? userTransactionsRef;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  bool allowTransactionSubmit = false;

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String? selectedCategory;
  bool transactionSubmitted = false;
  double totalMonthlyBudget = 0;
  double totalMonthlySpend = 0;
  int? income;
  double gradient = 0.1;
  double opacity = 0.5;
  bool transactionsLoaded = false;

  List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
  }

  void changeMonth(decrease_month) {
    if (decrease_month) {
      setState(() {
        startDate = DateTime(startDate.year, startDate.month - 1, 1);
        endDate = DateTime(endDate.year, endDate.month, 0);
      });
    } else {
      setState(() {
        startDate = DateTime(startDate.year, startDate.month + 1, 1);
        endDate = DateTime(endDate.year, endDate.month + 2, 0);
      });
    }
    totalMonthlySpend = 0;
    getTransactions();
  }

  Future<void> getCategories() async {
    // Get docs from collection reference
    userDocument =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    userDocument!.get().then((documentSnapshot) => {
          setState(() {
            income = documentSnapshot.get('income');
            print('income: ${income}');
          })
        });
    userCategoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection("category_and_budget");

    QuerySnapshot querySnapshot = await userCategoryRef!.get();
    categories = querySnapshot.docs.map((doc) => doc.data() as Map).toList();
    categories.forEach((element) {
      categoryList.add(element['name']);
      setState(() {
        totalMonthlyBudget += element['amount'];
      });
      print(totalMonthlyBudget);
    });
    categoryList.add('Others');

    print('Categories: ${categories}');
    print('Categories: ${categoryList}');
  }

  Future<void> getTransactions() async {
    // Get docs from collection reference
    userTransactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection("transactions");

    QuerySnapshot querySnapshot = await userCategoryRef!.get();

    querySnapshot = await userTransactionsRef!
        .where("datetime", isGreaterThanOrEqualTo: startDate)
        .where("datetime", isLessThanOrEqualTo: endDate)
        .get();
    transactions = querySnapshot.docs.map((doc) => doc.data() as Map).toList();
    if (transactions.isEmpty) {
      setState(() {
        gradient = 0.1;
        opacity = 0.5;
      });
    } else {
      transactions.forEach((element) {
        setState(() {
          totalMonthlySpend += element['amount'];
          gradient = (totalMonthlySpend / totalMonthlyBudget) * 0.4 + 0.1;
          opacity = (totalMonthlySpend / totalMonthlyBudget) * 0.5 + 0.5;
          transactionsLoaded = true;

          print(gradient);
          print(opacity);
        });
        print(totalMonthlySpend);
      });
    }

    print('Transactions: ${transactions}');
  }

  void deleteTransactionDialog(collectionReference, doc_id) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialogTwoOptions(
              title: "Delete transaction",
              content: "Are you sure you want to delete this transaction?",
              buttonTextA: "Cancel",
              buttonTextB: "Banish it",
              context: context);
        }).then((value) {
      if (value == 1) {
        FirebaseInteractions.deleteTransaction(collectionReference, doc_id);
        totalMonthlySpend = 0;
        getTransactions();
      }
    });
  }

  void addTransactionDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(width! * 0.05),
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              elevation: 10,
              content: Container(
                  padding: EdgeInsets.all(15),
                  height: height! * 0.5,
                  width: width! * 0.8,
                  child: Column(
                    children: [
                      Text("Add a new transaction"),
                      DropdownButton(
                        hint: selectedCategory == null
                            ? Text('Select a category')
                            : Text(
                                selectedCategory!), // Not necessary for Option 1
                        onChanged: (value) {
                          print('ok');
                          if (amountController.text.isNotEmpty) {
                            setState(() {
                              allowTransactionSubmit = true;
                            });
                          } else {
                            setState(() {
                              allowTransactionSubmit = false;
                            });
                          }
                          setState(() {
                            selectedCategory = value as String?;
                          });
                        },
                        items: categoryList.map((category) {
                          return DropdownMenuItem(
                            child: Text(category),
                            value: category,
                          );
                        }).toList(),
                      ),
                      TextFormField(
                        onChanged: (value) {
                          if (amountController.text.isNotEmpty &&
                              selectedCategory != null) {
                            setState(() {
                              allowTransactionSubmit = true;
                            });
                          } else {
                            setState(() {
                              allowTransactionSubmit = false;
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                        controller: amountController,
                        decoration: const InputDecoration(labelText: "Amount"),
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: "Description"),
                      ),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: !allowTransactionSubmit
                                ? Colors.grey
                                : ColorTheme().gradientGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5.0,
                          ),
                          onPressed: () {
                            if (allowTransactionSubmit) {
                              Map<String, dynamic> tempMap = {
                                "amount": double.parse(amountController.text),
                                "category": selectedCategory,
                                "description":
                                    descriptionController.text.isEmpty
                                        ? ""
                                        : descriptionController.text,
                                "datetime": DateTime.now(),
                              };
                              FirebaseInteractions.submitTransaction(
                                  userDocument, tempMap);
                              setState(() {
                                transactionSubmitted = true;
                                selectedCategory = null;
                              });
                              Navigator.pop(context);
                            } else {
                              const snackBar = SnackBar(
                                content: Text('Please enter an amount'),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                          },
                          child: Text("Submit"))
                    ],
                  )),
            );
          });
        }).then((value) {
      if (transactionSubmitted) {
        setState(() {
          totalMonthlySpend += double.parse(amountController.text);
          transactionSubmitted = false;
        });
      }
      setState(() {
        selectedCategory = null;
        allowTransactionSubmit = false;
      });
      descriptionController.clear();
      amountController.clear();
    });
  }

  void showTransactionDetailsDialog(amount, datetime, category, description) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              insetPadding: EdgeInsets.all(width! * 0.05),
              contentPadding: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              elevation: 10,
              content: Container(
                  padding: const EdgeInsets.all(15),
                  height: height! * 0.3,
                  width: width! * 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: ColorTheme().gradientGrey, fontSize: 20),
                      ),
                      Text(
                        'Spent on',
                        style: TextStyle(
                            color: ColorTheme().gradientGrey, fontSize: 20),
                      ),
                      Text(
                        DateFormat.MMMMEEEEd().format(datetime.toDate()),
                        style: TextStyle(
                            color: ColorTheme().gradientGrey, fontSize: 20),
                      ),
                      Text(description == "" ? "No description" : description),
                    ],
                  )));
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!dataRetrieved) {
      getCategories();
      getTransactions();
      print('Start date: ${startDate.day}');
      print('End date: ${endDate.day}');
      setState(() {
        dataRetrieved = true;
      });
    }

    CollectionReference users = FirebaseFirestore.instance.collection('users');

    print("in home page");

    return FutureBuilder<DocumentSnapshot>(
        future: users.doc(user!.uid).get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                appBar: AppBar(
                  title: const Text("Home page"),
                ),
                body: const Center(child: Text("Oops, something went wrong")));
          } else if (snapshot.hasData && !snapshot.data!.exists) {
            users.doc(user!.uid) // <-- Document ID
                .set({
              'email': user!.email,
              'income': 0,
              'id': user!.uid
            }) // <-- Your data
                .then((_) {
              users.doc((user!.uid));
              print('Added');
              return SetupPage();
            }).catchError((error) {
              print('Add failed: $error');
              return HomePage();
            });
            return SetupPage();
          } else if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Scaffold(
                body: AnimatedContainer(
                  curve: Curves.fastOutSlowIn,
                  duration: Duration(seconds: 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          stops: [
                            gradient,
                            0.9
                          ],
                          colors: [
                            ColorTheme().backgroundPurple.withOpacity(opacity),
                            ColorTheme().backgroundGreen
                          ])),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: height! * 0.05),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          MaterialPageRoute(
                                            builder: (BuildContext context) =>
                                                LoginPage(),
                                          ),
                                          (route) => false);
                                    },
                                    child: Text("Logout")),
                                TextButton(
                                    onPressed: () async {
                                      addTransactionDialog();
                                    },
                                    child: Text("Add transaction")),
                              ]),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                                onPressed: () async {
                                  Navigator.pushNamed(
                                      context, SetIncomePage.routeName);
                                },
                                child: Text("Change income")),
                            TextButton(
                                onPressed: () async {
                                  Navigator.pushNamed(
                                      context, SetCategoryPage.routeName);
                                },
                                child: Text("Change categories")),
                          ],
                        ),
                        SizedBox(
                          height: height! * 0.02,
                        ),
                        Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 0,
                            color: Color.fromARGB(57, 255, 255, 255),
                            margin: EdgeInsets.fromLTRB(15, 0, 15, 10),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Container(
                                    width: width! * 0.9,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Expenditure',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: ColorTheme().gradientPurple,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(
                                        0, 0, 0, height! * 0.01),
                                    width: width! * 0.95,
                                    child: SfLinearGauge(
                                        minimum: 0,
                                        maximum: totalMonthlyBudget,
                                        showLabels: false,
                                        showTicks: false,
                                        axisTrackStyle: LinearAxisTrackStyle(
                                            thickness: 15,
                                            edgeStyle:
                                                LinearEdgeStyle.bothCurve),
                                        barPointers: [
                                          LinearBarPointer(
                                              color:
                                                  ColorTheme().gradientPurple,
                                              value: totalMonthlySpend,
                                              // Changed the thickness to make the curve visible
                                              thickness: 15,
                                              //Updated the edge style as curve at end position
                                              edgeStyle:
                                                  LinearEdgeStyle.bothCurve)
                                        ],
                                        markerPointers: [
                                          LinearWidgetPointer(
                                              value: totalMonthlySpend,
                                              offset: 10,
                                              position:
                                                  LinearElementPosition.inside,
                                              child: Card(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10.0),
                                                ),
                                                elevation: 0,
                                                color: Color.fromARGB(
                                                    100, 255, 255, 255),
                                                margin: EdgeInsets.fromLTRB(
                                                    15, 0, 15, 0),
                                                child: Container(
                                                  padding: EdgeInsets.all(5),
                                                  child: Text(
                                                      '\$${totalMonthlySpend.toStringAsFixed(2)}'),
                                                ),
                                              )),
                                          LinearWidgetPointer(
                                            value: totalMonthlyBudget,
                                            offset: 10,
                                            position:
                                                LinearElementPosition.outside,
                                            child: Text(
                                                '\$${totalMonthlyBudget.toStringAsFixed(2)}'),
                                          ),
                                        ]),
                                  ),
                                ],
                              ),
                            )),
                        Text(
                          startDate.month == DateTime.now().month
                              ? 'Potential savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}'
                              : 'Savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            color: ColorTheme().gradientGreen,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                onPressed: () {
                                  changeMonth(true);
                                },
                                icon: Icon(Icons.arrow_back_ios_rounded)),
                            Container(
                              alignment: Alignment.center,
                              child: Text(
                                'All transactions for ${months[startDate.month - 1]}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorTheme().gradientGreen,
                                ),
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  if (startDate.month == DateTime.now().month &&
                                      startDate.year == DateTime.now().year) {
                                    return null;
                                  } else {
                                    changeMonth(false);
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: startDate.month == DateTime.now().month
                                      ? Colors.grey
                                      : Colors.black,
                                )),
                          ],
                        ),
                        StreamBuilder(
                          stream: userTransactionsRef
                              ?.where("datetime",
                                  isGreaterThanOrEqualTo: startDate)
                              .where("datetime", isLessThanOrEqualTo: endDate)
                              .orderBy("datetime", descending: true)
                              .snapshots(),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                  height: height! * 0.5,
                                  child: Center(
                                    child: SpinKitFadingCircle(
                                        color: Colors.white),
                                  ));
                            } else {
                              return Container(
                                height: height! * 0.5,
                                child: ListView(
                                  shrinkWrap: true,
                                  children:
                                      snapshot.data!.docs.map((transactions) {
                                    return Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      elevation: 0,
                                      color: Color.fromARGB(57, 255, 255, 255),
                                      margin:
                                          EdgeInsets.fromLTRB(15, 0, 15, 10),
                                      child: ListTile(
                                        onLongPress: ((() {
                                          deleteTransactionDialog(
                                              userTransactionsRef,
                                              transactions.id);
                                        })),
                                        onTap: (() {
                                          showTransactionDetailsDialog(
                                              transactions['amount'],
                                              transactions['datetime'],
                                              transactions['category'],
                                              transactions['description']);
                                        }),
                                        title: Text(
                                          '\$${transactions['amount'].toStringAsFixed(2)}',
                                          maxLines: 1,
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          transactions['category'],
                                          maxLines: 1,
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              DateFormat.MMMMEEEEd().format(
                                                  transactions['datetime']
                                                      .toDate()),
                                              maxLines: 1,
                                            ),
                                            Text(
                                              DateFormat.jm().format(
                                                  transactions['datetime']
                                                      .toDate()),
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        stops: [
                          0.1,
                          0.9
                        ],
                        colors: [
                          ColorTheme().backgroundPurple.withOpacity(0.5),
                          ColorTheme().backgroundGreen
                        ])),
                child: Center(),
              ),
            );
          }
        });
  }
}
