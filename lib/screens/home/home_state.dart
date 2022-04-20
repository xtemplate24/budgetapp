import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/custom_expansion_tile.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:syncfusion_flutter_charts/charts.dart';
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
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String? selectedCategory;
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
        endDate = DateTime(endDate.year, endDate.month, 0);
      });
    } else {
      setState(() {
        startDate = DateTime(startDate.year, startDate.month + 1, 1);
        endDate = DateTime(endDate.year, endDate.month + 2, 0);
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
          spendingByCategory[element['category']] += element['amount'];
          totalMonthlySpend += element['amount'];
          gradient = (totalMonthlySpend / totalMonthlyBudget) * 0.4 + 0.1;
          opacity = (totalMonthlySpend / totalMonthlyBudget) * 0.5 + 0.5;
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
        }).then((value) async {
      if (value == 1) {
        FirebaseInteractions.deleteTransaction(collectionReference, doc_id);
        totalMonthlySpend = 0;
        await getTransactions().then((value) {
          populateChart();
        });
        ;
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
        populateChart();
      }
      setState(() {
        selectedCategory = null;
        allowTransactionSubmit = false;
      });
      descriptionController.clear();
      amountController.clear();
    });
  }

  Future<void> getCategoriesThenTransactions() async {
    await getCategories().then((value) => getTransactions());
  }

  @override
  Widget build(BuildContext context) {
    if (!dataRetrieved) {
      getCategoriesThenTransactions();
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
                floatingActionButton: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FloatingActionButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    onPressed: () async {
                      addTransactionDialog();
                    },
                    elevation: 3,
                    backgroundColor: ColorTheme().gradientPurple,
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
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Column(
                              children: [
                                Container(
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
                                    title: Text(
                                      startDate.month == DateTime.now().month
                                          ? 'Potential savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}'
                                          : 'Savings: \$${income == null ? "Loading" : (income! - totalMonthlySpend).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: ColorTheme().gradientGreen,
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
                              return Expanded(
                                //height: height! * 0.5,
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
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
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
                                            contentPadding: EdgeInsets.fromLTRB(
                                                30, 0, 0, 0),
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
                                          children: [
                                            Container(
                                                padding: EdgeInsets.fromLTRB(
                                                    30, 0, 0, 20),
                                                alignment: Alignment.centerLeft,
                                                child: transactions[
                                                            'description'] ==
                                                        ""
                                                    ? Text("No description")
                                                    : Text(transactions[
                                                        'description']))
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

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
