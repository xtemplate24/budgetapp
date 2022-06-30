import 'dart:ui';

import 'package:blurrycontainer/blurrycontainer.dart';
import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/custom_expansion_tile.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/firebase_interactions/firebase_interactions.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/home/loading_home.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:budgetapp/screens/setCategory/set_category_page.dart';
import 'package:budgetapp/screens/setIncome/set_income_page.dart';
import 'package:budgetapp/screens/setup/setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:flutter_animated_dialog/flutter_animated_dialog.dart';

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
  final TextEditingController exchangeController = TextEditingController();
  bool allowTransactionSubmit = false;
  List<Color> chartColors = [
    ColorTheme().chart1,
    ColorTheme().chart2,
    ColorTheme().chart3,
    ColorTheme().chart4,
    ColorTheme().chart5,
    ColorTheme().chart6,
    ColorTheme().chart7,
    ColorTheme().chart8,
  ];

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  String? selectedCategory;
  double exchangeRate = 1;
  bool transactionSubmitted = false;
  double totalMonthlyBudget = 0;
  double totalMonthlySpend = 0;
  int? income;
  double gradient = 0.1;
  double opacity = 0.5;
  bool transactionsLoaded = false;
  Map spendingByCategory = {};
  Map budgetByCategory = {};
  Map percentageSpendByCategory = {};
  List<String> options = [
    'Item1',
    'Item2',
    'Item3',
    'Item4',
  ];

  List<ChartData> chartData = <ChartData>[];
  late TooltipBehavior _tooltipBehavior;
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
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      color: Color.fromARGB(100, 255, 255, 255),
      opacity: 0.7,
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex,
          int seriesIndex) {
        return Container(
            padding: EdgeInsets.all(5),
            color: Color.fromARGB(100, 255, 255, 255),
            child: Text(
                '${categoryList[seriesIndex]} : \$${spendingByCategory[categoryList[seriesIndex]].toStringAsFixed(2)} / \$${budgetByCategory[categoryList[seriesIndex]].toStringAsFixed(2)}'));
      },
      // tooltipPosition: TooltipPosition.pointer,
    );
    super.initState();
    height = 100.h;
    width = 100.w;
  }

  void changeMonth(decrease_month) {
    if (decrease_month) {
      setState(() {
        startDate = DateTime(startDate.year, startDate.month - 1, 1);
        endDate = DateTime(endDate.year, endDate.month - 1, 1);
      });
    } else {
      setState(() {
        startDate = DateTime(startDate.year, startDate.month + 1, 1);
        endDate = DateTime(endDate.year, endDate.month + 1, 1);
      });
    }
    spendingByCategory.forEach((key, value) {
      spendingByCategory[key] = 0;
    });
    chartData = [];
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
      spendingByCategory[element['name']] = 0;
      budgetByCategory[element['name']] = element['amount'];
      setState(() {
        totalMonthlyBudget += element['amount'];
      });
      print(totalMonthlyBudget);
    });
    print('map: ${spendingByCategory}');
    print('map: ${budgetByCategory}');
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
        .where("datetime", isLessThan: endDate)
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
          spendingByCategory[element['category']] += element['amount'];
          totalMonthlySpend += element['amount'];
          double tempGradient =
              (totalMonthlySpend / totalMonthlyBudget) * 0.4 + 0.1;
          double tempOpacity =
              opacity = (totalMonthlySpend / totalMonthlyBudget) * 0.5 + 0.5;
          gradient = tempGradient > 0.5 ? 0.5 : tempGradient;
          opacity = tempOpacity > 1 ? 1 : tempOpacity;
          transactionsLoaded = true;
        });
      });
    }

    print('Transactions: ${transactions}');
    print('map: ${spendingByCategory}');

    populateChart();
  }

  void populateChart() {
    int x = 0;
    setState(() {
      chartData = [];
      spendingByCategory.forEach((key, value) {
        double temp_num = spendingByCategory[key] / budgetByCategory[key];
        chartData.add(ChartData(key, temp_num, chartColors[x]));
        if (x == 7) {
          x = 0;
        } else {
          x += 1;
        }
      });
    });
  }

  Future<bool> deleteTransactionDialog(collectionReference, doc_id) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialogTwoOptions(
              title: "Delete transaction",
              content: "Are you sure you want to delete this transaction?",
              buttonTextA: "Cancel",
              buttonTextB: "Banish it",
              context: context);
        }).then((value) async {
      if (value == 1) {
        FirebaseInteractions.deleteTransaction(collectionReference, doc_id);
        totalMonthlySpend = 0;
        await getTransactions().then((value) {
          populateChart();
        });
        return true;
      } else {
        return false;
      }
    });
    return false;
  }

  void optionsDialog() {
    showAnimatedDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Color.fromARGB(12, 0, 0, 0),
        animationType: DialogTransitionType.slideFromRight,
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: 400),
        builder: (context) {
          return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, height! * 0.09, 15, 20),
                child: BlurryContainer(
                    blur: 5,
                    bgColor: Colors.white,
                    padding: EdgeInsets.all(10),
                    height: 125,
                    width: 200,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        ])),
              ));
        });
  }

  void addTransactionDialog() {
    showAnimatedDialog(
        barrierDismissible: true,
        barrierColor: Color.fromARGB(12, 0, 0, 0),
        animationType: DialogTransitionType.slideFromBottom,
        curve: Curves.fastOutSlowIn,
        duration: Duration(milliseconds: 450),
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.all(width! * 0.05),
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              elevation: 0,
              content: BlurryContainer(
                  blur: 5,
                  bgColor: Colors.white,
                  padding: EdgeInsets.all(40),
                  height: height! * 0.5,
                  width: width! * 0.8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          padding: EdgeInsets.all(0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "New\nTransaction",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color: ColorTheme().gradientGreen,
                                fontSize: 30),
                          )),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: DropdownButton(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          hint: selectedCategory == null
                              ? Text('Select a category')
                              : Text(
                                  selectedCategory!), // Not necessary for Option 1
                          onChanged: (value) {
                            print('ok');
                            if (amountController.text.isNotEmpty &&
                                exchangeController.text.isNotEmpty) {
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
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: TextFormField(
                              onChanged: (value) {
                                if (amountController.text.isNotEmpty &&
                                    exchangeController.text.isNotEmpty &&
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
                              decoration:
                                  const InputDecoration(labelText: "Amount"),
                            ),
                          ),
                          SizedBox(
                            width: width! * 0.05,
                          ),
                          Flexible(
                            child: TextFormField(
                              onChanged: (value) {
                                if (amountController.text.isNotEmpty &&
                                    exchangeController.text.isNotEmpty &&
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
                              controller: exchangeController,
                              decoration: const InputDecoration(
                                  labelText: "Exchange rate"),
                            ),
                          ),
                        ],
                      ),
                      exchangeController.text.isNotEmpty &&
                              amountController.text.isNotEmpty
                          ? double.parse(exchangeController.text) != 1.0
                              ? Container(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "SGD " +
                                        (double.parse(amountController.text) /
                                                double.parse(
                                                    exchangeController.text))
                                            .toStringAsFixed(2),
                                    style: TextStyle(fontSize: 13),
                                  ))
                              : Container()
                          : Container(),
                      TextFormField(
                        controller: descriptionController,
                        decoration:
                            const InputDecoration(labelText: "Description"),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  width! * 0.2, 15, width! * 0.2, 15),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                    fontSize: 17, color: Colors.white),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: ColorTheme().gradientGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5.0,
                            ),
                            onPressed: () {
                              if (allowTransactionSubmit) {
                                FirebaseInteractions.updateExchangeRate(
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user!.uid),
                                    double.parse(exchangeController.text));
                                Map<String, dynamic> tempMap = {
                                  "amount":
                                      double.parse(amountController.text) /
                                          double.parse(exchangeController.text),
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
                            }),
                      ),
                    ],
                  )),
            );
          });
        }).then((value) {
      if (transactionSubmitted) {
        setState(() {
          totalMonthlySpend += (double.parse(amountController.text) /
              double.parse(exchangeController.text));
          transactionSubmitted = false;
        });
        populateChart();
      }

      selectedCategory = null;
      allowTransactionSubmit = false;

      descriptionController.clear();
      amountController.clear();
    });
  }

  Future<void> getCategoriesThenTransactions() async {
    await getCategories().then((value) => getTransactions());
  }

  Future<void> getExchangeRate() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((val) {
      double temp = val.data()!['exchange_rate'];
      print(temp);
      if (temp == null) {
        FirebaseInteractions.updateExchangeRate(
            FirebaseFirestore.instance.collection('users').doc(user!.uid), 1.0);
      } else {
        setState(() {
          exchangeRate = temp;
        });
      }
      exchangeController.text = exchangeRate.toString();
    }).catchError((error) {
      print("an error occured");
      print(error);
      return -1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!dataRetrieved) {
      getCategoriesThenTransactions();
      getExchangeRate();
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
              Navigator.popAndPushNamed(context, SetupPage.routeName);
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
                floatingActionButton: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FloatingActionButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    onPressed: () async {
                      addTransactionDialog();
                    },
                    elevation: 3,
                    backgroundColor: ColorTheme().chart1,
                    child: Icon(
                      Icons.add_box_rounded,
                    ),
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerFloat,
                body: Container(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.all(10),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
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
                                    icon: Icon(
                                      Icons.logout_rounded,
                                      color: ColorTheme().gradientGreen,
                                    )),
                                IconButton(
                                    onPressed: () {
                                      optionsDialog();
                                    },
                                    icon: Icon(
                                      Icons.settings_rounded,
                                      color: ColorTheme().gradientGreen,
                                    ))
                              ]),
                        ),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 0,
                          color: Color.fromARGB(57, 255, 255, 255),
                          margin: EdgeInsets.fromLTRB(15, 0, 15, 10),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                                  width: width! * 0.9,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${months[startDate.month - 1]}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: ColorTheme().gradientGreen,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.only(left: 10),
                                  margin: EdgeInsets.all(0),
                                  width: width! * 0.95,
                                  child: SfLinearGauge(
                                      minimum: 0,
                                      maximum: totalMonthlyBudget,
                                      showLabels: false,
                                      showTicks: false,
                                      axisTrackStyle: LinearAxisTrackStyle(
                                          thickness: 15,
                                          edgeStyle: LinearEdgeStyle.bothCurve),
                                      barPointers: [
                                        LinearBarPointer(
                                            color: ColorTheme().chart1,
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
                                                    BorderRadius.circular(10.0),
                                              ),
                                              elevation: 0,
                                              color: totalMonthlySpend >=
                                                      totalMonthlyBudget
                                                  ? Color.fromARGB(
                                                      98, 255, 136, 136)
                                                  : Color.fromARGB(
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
                                Theme(
                                  data: Theme.of(context).copyWith(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      dividerColor: Colors.transparent,
                                      unselectedWidgetColor:
                                          ColorTheme().gradientGrey,
                                      colorScheme: ColorScheme.light(
                                        primary: ColorTheme().gradientGreen,
                                      )),
                                  child: CustomExpansionTile(
                                    tilePadding: EdgeInsets.all(0),
                                    title: Container(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Text(
                                        startDate.month == DateTime.now().month
                                            ? 'Potential savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}'
                                            : 'Savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: ColorTheme().gradientGreen,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Container(
                                          height: height! * 0.3,
                                          child: charts.SfCircularChart(
                                            tooltipBehavior: _tooltipBehavior,
                                            series: <
                                                charts.CircularSeries<ChartData,
                                                    String>>[
                                              charts.RadialBarSeries<ChartData,
                                                      String>(
                                                  maximumValue: 1,
                                                  radius: '100%',
                                                  trackOpacity: 0.7,
                                                  gap: '3%',
                                                  dataSource: chartData,
                                                  cornerStyle: charts
                                                      .CornerStyle.bothCurve,
                                                  xValueMapper:
                                                      (ChartData data, _) =>
                                                          data.x,
                                                  yValueMapper:
                                                      (ChartData data, _) =>
                                                          data.y,
                                                  pointColorMapper:
                                                      (ChartData data, _) =>
                                                          data.color)
                                            ],
                                            legend: Legend(
                                              iconHeight: 30,
                                              textStyle: GoogleFonts.cabin(),
                                              isVisible: true,
                                              // Overflowing legend content will be wraped
                                              overflowMode:
                                                  LegendItemOverflowMode.wrap,
                                            ),
                                          )),
                                      // Container(
                                      //     child:
                                      //         startDate.month ==
                                      //                 DateTime.now().month
                                      //             ? Column(
                                      //                 children: [
                                      //                   Text(
                                      //                     totalMonthlySpend /
                                      //                                 totalMonthlyBudget >
                                      //                             (startDate.day /
                                      //                                     DateTime(startDate.year, startDate.month + 1, 0)
                                      //                                         .day) *
                                      //                                 totalMonthlyBudget
                                      //                         ? "Spending rate optimal ${                 totalMonthlySpend /
                                      //                                 totalMonthlyBudget >
                                      //                             (startDate.day /
                                      //                                     DateTime(startDate.year, startDate.month + 1, 0)
                                      //                                         .day) *
                                      //                                 totalMonthlyBudget}"
                                      //                         : 'Spending rate not optimal ${                 totalMonthlySpend /
                                      //                                 totalMonthlyBudget >
                                      //                             (startDate.day /
                                      //                                     DateTime(startDate.year, startDate.month + 1, 0)
                                      //                                         .day) *
                                      //                                 totalMonthlyBudget}',
                                      //                     style: TextStyle(
                                      //                       fontSize: 15,
                                      //                       color: ColorTheme()
                                      //                           .gradientGreen,
                                      //                     ),
                                      //                   ),
                                      //                   SfLinearGauge(
                                      //                     barPointers: [
                                      //                       LinearBarPointer(
                                      //                           value: 50,
                                      //                           // Changed the thickness to make the curve visible
                                      //                           thickness: 10,
                                      //                           //Updated the edge style as curve at end position
                                      //                           edgeStyle:
                                      //                               LinearEdgeStyle
                                      //                                   .bothCurve)
                                      //                     ],
                                      //                   ),
                                      //                 ],
                                      //               )
                                      //             : Container()),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                                onPressed: () {
                                  changeMonth(true);
                                },
                                icon: Icon(
                                  Icons.arrow_left_rounded,
                                  color: ColorTheme().gradientGrey,
                                  size: 40,
                                )),
                            Container(
                              alignment: Alignment.center,
                              child: Text(
                                'Change month',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorTheme().gradientGreen,
                                ),
                              ),
                            ),
                            IconButton(
                                padding: EdgeInsets.only(right: 5),
                                onPressed: () {
                                  if (startDate.month == DateTime.now().month &&
                                      startDate.year == DateTime.now().year) {
                                    return null;
                                  } else {
                                    changeMonth(false);
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_right_rounded,
                                  size: 40,
                                  color: startDate.month == DateTime.now().month
                                      ? Colors.grey
                                      : ColorTheme().gradientGrey,
                                )),
                          ],
                        ),
                        StreamBuilder(
                          stream: userTransactionsRef
                              ?.where("datetime",
                                  isGreaterThanOrEqualTo: startDate)
                              .where("datetime", isLessThan: endDate)
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
                              return Expanded(
                                //height: height! * 0.5,
                                child: ListView(
                                  padding: EdgeInsets.only(top: 10),
                                  shrinkWrap: true,
                                  children:
                                      snapshot.data!.docs.map((transactions) {
                                    return Dismissible(
                                      key: UniqueKey(),
                                      confirmDismiss: (val) async {
                                        return await deleteTransactionDialog(
                                            userTransactionsRef,
                                            transactions.id);
                                      },
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                          alignment: Alignment.centerRight,
                                          padding:
                                              EdgeInsets.fromLTRB(0, 0, 30, 10),
                                          child: Icon(
                                              Icons.delete_outline_rounded,
                                              color:
                                                  ColorTheme().gradientPurple)),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        elevation: 0,
                                        color:
                                            Color.fromARGB(57, 255, 255, 255),
                                        margin:
                                            EdgeInsets.fromLTRB(15, 0, 15, 10),
                                        child: Theme(
                                          data: Theme.of(context).copyWith(
                                              splashColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              dividerColor: Colors.transparent,
                                              unselectedWidgetColor:
                                                  ColorTheme().gradientGrey,
                                              colorScheme: ColorScheme.light(
                                                primary:
                                                    ColorTheme().gradientGreen,
                                              )),
                                          child: CustomExpansionTile(
                                            trailing: Icon(
                                              Icons.arrow_drop_down_rounded,
                                              size: 0,
                                            ),
                                            tilePadding: EdgeInsets.all(0),
                                            title: ListTile(
                                              contentPadding:
                                                  EdgeInsets.fromLTRB(
                                                      30, 0, 0, 0),
                                              title: Text(
                                                '\$${transactions['amount'].toStringAsFixed(2)}',
                                                maxLines: 1,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
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
                                                    DateFormat.MMMMd().format(
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
                                            children: [
                                              Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  padding: EdgeInsets.fromLTRB(
                                                      30, 0, 30, 20),
                                                  child: transactions[
                                                              'description'] ==
                                                          ""
                                                      ? Text("No description")
                                                      : Text(transactions[
                                                          'description'])),
                                            ],
                                          ),
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
            return LoadingHome().tempLoadingScreen();
          }
        });
  }
}

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
