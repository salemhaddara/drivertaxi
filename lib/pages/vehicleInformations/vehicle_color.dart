import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tagxibiddingdriver/functions/functions.dart';
import 'package:tagxibiddingdriver/pages/NavigatorPages/managevehicles.dart';
import 'package:tagxibiddingdriver/pages/loadingPage/loading.dart';
import 'package:tagxibiddingdriver/pages/login/signupmethod.dart';
import 'package:tagxibiddingdriver/pages/onTripPage/map_page.dart';
import 'package:tagxibiddingdriver/pages/noInternet/nointernet.dart';
import 'package:tagxibiddingdriver/pages/onTripPage/rides.dart';
import 'package:tagxibiddingdriver/pages/vehicleInformations/referral_code.dart';
import 'package:tagxibiddingdriver/styles/styles.dart';
import 'package:tagxibiddingdriver/translation/translation.dart';
import 'package:tagxibiddingdriver/widgets/widgets.dart';

List<Map<dynamic, dynamic>> data = [];

class VehicleColor extends StatefulWidget {
  List<Map<dynamic, dynamic>>? data;
  VehicleColor({Key? key, this.data}) : super(key: key);

  @override
  State<VehicleColor> createState() => _VehicleColorState();
}

dynamic vehicleColor;

class _VehicleColorState extends State<VehicleColor> {
  bool _isLoading = false;
  TextEditingController controller = TextEditingController();

  String uploadError = '';

//navigate
  navigateRef() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Referral()),
        (route) => false);
  }

  navigateMap() {
    if (userDetails['enable_bidding'] == true) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RidePage()),
          (route) => false);
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
          (route) => false);
    }
  }

  navigateLogout() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const SignupMethod()));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    if (widget.data != null) {
      data.addAll(widget.data!);
    }
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
                            languages[choosenLanguage]['text_vehicle_color'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * twenty,
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      InputField(
                        text: languages[choosenLanguage]
                            ['Text_enter_vehicle_color'],
                        textController: controller,
                        onTap: (val) {
                          setState(() {
                            vehicleColor = controller.text;
                          });
                        },
                      ),
                      (uploadError != '')
                          ? Container(
                              width: media.width * 0.8,
                              margin: const EdgeInsets.only(top: 20),
                              child: Text(
                                uploadError,
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * sixteen,
                                    color: Colors.red),
                              ),
                            )
                          : Container(),
                      const SizedBox(
                        height: 40,
                      ),
                      (controller.text.isNotEmpty)
                          ? Button(
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                setState(() {
                                  _isLoading = true;
                                });
                                if (userDetails.isEmpty) {
                                  var reg = await registerDriver();
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  print('reg : $reg ');
                                  if (reg == 'true') {
                                    navigateRef();
                                    serviceLocations.clear();
                                    vehicleMake.clear();
                                    vehicleModel.clear();
                                    vehicleType.clear();
                                  } else {
                                    setState(() {
                                      uploadError = reg.toString();
                                    });
                                  }
                                } else if (userDetails['role'] == 'owner') {
                                  var reg = await addDriver();
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  if (reg == 'true') {
                                    // ignore: use_build_context_synchronously
                                    showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return AlertDialog(
                                            content: Container(
                                              width: media.width * 0.8,
                                              color: Colors.white,
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_vehicle_added'],
                                                style:
                                                    TextStyle(color: textColor),
                                              ),
                                            ),
                                            actions: [
                                              Button(
                                                  width: media.width * 0.2,
                                                  height: media.width * 0.1,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              const ManageVehicles()),
                                                    );
                                                  },
                                                  text: "OK")
                                            ],
                                          );
                                        });

                                    serviceLocations.clear();
                                    vehicleMake.clear();
                                    vehicleModel.clear();
                                    vehicleType.clear();
                                  } else if (reg == 'logout') {
                                    navigateLogout();
                                  } else {
                                    setState(() {
                                      uploadError = reg.toString();
                                    });
                                  }
                                } else {
                                  var update = await updateVehicle();
                                  if (update == 'success') {
                                    navigateMap();
                                    serviceLocations.clear();
                                    vehicleMake.clear();
                                    vehicleModel.clear();
                                    vehicleType.clear();
                                  } else if (update == 'logout') {
                                    navigateLogout();
                                  }
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
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

          //loader
          (_isLoading == true)
              ? const Positioned(top: 0, child: Loading())
              : Container()
        ],
      ),
    ));
  }
}
