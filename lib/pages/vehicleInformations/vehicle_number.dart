import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxibiddingdriver/functions/functions.dart';
import 'package:tagxibiddingdriver/pages/noInternet/nointernet.dart';
import 'package:tagxibiddingdriver/pages/vehicleInformations/vehicle_color.dart';
import 'package:tagxibiddingdriver/styles/styles.dart';
import 'package:tagxibiddingdriver/translation/translation.dart';
import 'package:tagxibiddingdriver/widgets/widgets.dart';

class VehicleNumber extends StatefulWidget {
  List<Map<dynamic, dynamic>>? data;
  VehicleNumber({Key? key, this.data}) : super(key: key);

  @override
  State<VehicleNumber> createState() => _VehicleNumberState();
}

dynamic vehicleNumber;

class _VehicleNumberState extends State<VehicleNumber> {
  TextEditingController controller = TextEditingController();
  @override
  void initState() {
    controller.text =
        extractNumbersFromFirst30Characters(widget.data![1]['clcb']);
    vehicleNumber =
        extractNumbersFromFirst30Characters(widget.data![1]['clcb']);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
        child: Directionality(
      textDirection:
          (languageDirection == 'rtl') ? TextDirection.rtl : TextDirection.ltr,
      child: Stack(
        children: [
          Container(
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              child: Column(children: [
                Container(
                  padding: EdgeInsets.only(
                      left: media.width * 0.08,
                      right: media.width * 0.08,
                      top: media.width * 0.05 +
                          MediaQuery.of(context).padding.top),
                  color: page,
                  height: media.height * 1,
                  width: media.width * 1,
                  child: Column(
                    children: [
                      Container(
                          width: media.width * 1,
                          color: topBar,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Icon(Icons.arrow_back)),
                            ],
                          )),
                      SizedBox(
                        height: media.height * 0.04,
                      ),
                      SizedBox(
                          width: media.width * 1,
                          child: Text(
                            languages[choosenLanguage]['text_license'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twenty,
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      InputField(
                        text: languages[choosenLanguage]['text_enter_vehicle'],
                        textController: controller,
                        onTap: (val) {
                          setState(() {
                            vehicleNumber = controller.text;
                          });
                        },
                        maxLength: 20,
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      (controller.text.length > 4 &&
                              controller.text.length < 21)
                          ? Button(
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => VehicleColor(
                                              data: widget.data,
                                            )));
                              },
                              text: languages[choosenLanguage]['text_next'])
                          : Container()
                    ],
                  ),
                ),
              ])),
          //no internet
          (internet == false)
              ? Positioned(
                  top: 0,
                  child: NoInternet(
                    onTap: () {
                      setState(() {
                        internetTrue();
                      });
                    },
                  ))
              : Container(),
        ],
      ),
    ));
  }

  String extractNumbersFromFirst30Characters(String inputString) {
    if (inputString.isEmpty) {
      return '';
    }
    String first10Characters = inputString.substring(0, 30);
    RegExp regex = RegExp(r'\d+');
    Iterable<Match> matches = regex.allMatches(first10Characters);
    String extractedNumbers = matches.map((match) => match.group(0)).join();

    return extractedNumbers;
  }
}
