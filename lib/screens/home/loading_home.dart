import 'package:budgetapp/components/color_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:sizer/sizer.dart';

class LoadingHome {
  final height = 100.h;
  final width = 100.w;
  Widget tempLoadingScreen() {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15.0))),
          onPressed: () {},
          elevation: 3,
          backgroundColor: ColorTheme().chart1,
          child: Icon(
            Icons.add_box_rounded,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(begin: Alignment.bottomCenter, stops: [
              0.1,
              0.9
            ], colors: [
              ColorTheme().backgroundPurple.withOpacity(0.5),
              ColorTheme().backgroundGreen
            ])),
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.all(10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.logout_rounded,
                        color: ColorTheme().gradientGreen,
                      )),
                  IconButton(
                      onPressed: () {},
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
                height: height * 0.215,
                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Center(
                                    child: SpinKitFadingCircle(
                                        color: Colors.white),
                                  ),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  onPressed: () {},
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
                  onPressed: () {},
                  icon: Icon(
                    Icons.arrow_right_rounded,
                    size: 40,
                    color: ColorTheme().gradientGrey,
                  )),
            ],
          ),
        ])),
      ),
    );
  }
}
