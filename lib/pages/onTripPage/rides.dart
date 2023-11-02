import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:tagxibiddingdriver/functions/functions.dart';
import 'package:tagxibiddingdriver/functions/notifications.dart';
import 'package:tagxibiddingdriver/pages/NavigatorPages/notification.dart';
import 'package:tagxibiddingdriver/pages/loadingPage/loading.dart';
import 'package:tagxibiddingdriver/pages/login/login.dart';
import 'package:tagxibiddingdriver/pages/login/signupmethod.dart';
import 'package:tagxibiddingdriver/pages/navDrawer/nav_drawer.dart';
import 'package:tagxibiddingdriver/pages/onTripPage/map_page.dart';
import 'package:tagxibiddingdriver/pages/vehicleInformations/docs_onprocess.dart';
import 'package:tagxibiddingdriver/styles/styles.dart';
import 'package:tagxibiddingdriver/translation/translation.dart';
import 'package:tagxibiddingdriver/widgets/widgets.dart';
import 'package:http/http.dart' as http;

class RidePage extends StatefulWidget {
  const RidePage({Key? key}) : super(key: key);

  @override
  State<RidePage> createState() => _RidePageState();
}

final distanceBetween = [
  {'name': '0-2 km', 'value': '0.43496'},
  {'name': '0-5 km', 'value': '1.0874'},
  {'name': '0-7 km', 'value': '1.7088'}
];
int _choosenDistance = 1;
List choosenRide = [];

class _RidePageState extends State<RidePage> with WidgetsBindingObserver {
  late geolocator.LocationPermission permission;
  int gettingPerm = 0;
  String state = '';
  bool _isLoading = false;
  bool _selectDistance = false;
  bool makeOnline = false;
  bool _cancel = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (userDetails['vehicle_types'] != []) {
      setState(() {
        vechiletypeslist = userDetails['driverVehicleType']['data'];
      });
    }
    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      isBackground = false;
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      isBackground = true;
    }
  }

  @override
  void dispose() {
    time?.cancel();
    bidStream?.cancel();
    super.dispose();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignupMethod()),
        (route) => false);
  }

//getting permission and current location
  getLocs() async {
    permission = await geolocator.GeolocatorPlatform.instance.checkPermission();
    serviceEnabled =
        await geolocator.GeolocatorPlatform.instance.isLocationServiceEnabled();

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;

      if (gettingPerm > 1) {
        locationAllowed = false;
        if (userDetails['active'] == true) {
          var val = await driverStatus();
          if (val == 'logout') {
            navigateLogout();
          }
        }
        state = '3';
      } else {
        state = '2';
      }
      setState(() {
        _isLoading = false;
      });
    } else if (permission == geolocator.LocationPermission.whileInUse ||
        permission == geolocator.LocationPermission.always) {
      if (serviceEnabled == true) {
        if (center == null) {
          var locs = await geolocator.Geolocator.getLastKnownPosition();
          if (locs != null) {
            center = LatLng(locs.latitude, locs.longitude);
            heading = locs.heading;
          } else {
            var loc = await geolocator.Geolocator.getCurrentPosition(
                desiredAccuracy: geolocator.LocationAccuracy.low);
            center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            heading = loc.heading;
          }
        }
        if (mounted) {
          setState(() {});
        }
      }

      if (makeOnline == true && userDetails['active'] == false) {
        var val = await driverStatus();
        if (val == 'logout') {
          navigateLogout();
        }
      }
      makeOnline = false;
      if (mounted) {
        setState(() {
          locationAllowed = true;
          state = '3';
          _isLoading = false;
        });
      }
    }
  }

  dynamic time;
  dynamic bidStream;
  List rideBck = [];
  timer() {
    bidStream = FirebaseDatabase.instance
        .ref()
        .child(
            'bid-meta/${choosenRide[0]["request_id"]}/drivers/${userDetails["id"]}')
        .onChildRemoved
        .handleError((onError) {
      bidStream?.cancel();
    }).listen((event) {
      if (driverReq.isEmpty) {
        getUserDetails();
      }
    });
    time = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (waitingList.isNotEmpty) {
        valueNotifierTimer.incrementNotifier();
      } else {
        timer.cancel();
        bidStream?.cancel();
        bidStream = null;
        time = null;
      }
    });
  }

  getLocationPermission() async {
    if (serviceEnabled == false) {
      await geolocator.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocator.LocationAccuracy.low);
    }
    if (await geolocator.GeolocatorPlatform.instance
        .isLocationServiceEnabled()) {
      if (permission == geolocator.LocationPermission.denied ||
          permission == geolocator.LocationPermission.deniedForever) {
        if (permission != geolocator.LocationPermission.deniedForever &&
            await geolocator.GeolocatorPlatform.instance
                .isLocationServiceEnabled()) {
          if (platform == TargetPlatform.android) {
            await perm.Permission.location.request();
            await perm.Permission.locationAlways.request();
          } else {
            await [perm.Permission.location].request();
          }
        }
      }
    }
    setState(() {
      _isLoading = true;
    });
    getLocs();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (platform == TargetPlatform.android) {
          platforms.invokeMethod('pipmode');
        }
        return false;
      },
      child: Material(
          child: (state != '1' && state != '2')
              ? ValueListenableBuilder(
                  valueListenable: valueNotifierHome.value,
                  builder: (context, value, child) {
                    if (time == null && waitingList.isNotEmpty) {
                      timer();
                    }
                    if (driverReq.isNotEmpty) {
                      choosenRide.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Maps()),
                            (route) => false);
                      });
                    }
                    if (isGeneral == true) {
                      isGeneral = false;
                      if (lastNotification != latestNotification) {
                        lastNotification = latestNotification;
                        pref.setString('lastNotification', latestNotification);
                        latestNotification = '';
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationPage()));
                        });
                      }
                    }
                    if (userDetails['approve'] == false && driverReq.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DocsProcess()),
                            (route) => false);
                      });
                    }
                    if (package == null) {
                      checkVersion();
                    }
                    return Directionality(
                      textDirection: (languageDirection == 'rtl')
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Scaffold(
                        drawer: const NavDrawer(),
                        body: Stack(
                          children: [
                            Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              padding: EdgeInsets.fromLTRB(
                                  media.width * 0.05,
                                  media.width * 0.05 +
                                      MediaQuery.of(context).padding.top,
                                  media.width * 0.05,
                                  media.width * 0.05),
                              color: page,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        height: media.width * 0.1,
                                        width: media.width * 0.1,
                                        decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 2,
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  spreadRadius: 2)
                                            ],
                                            color: page,
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.02)),
                                        child: StatefulBuilder(
                                            builder: (context, setState) {
                                          return InkWell(
                                              onTap: () async {
                                                Scaffold.of(context)
                                                    .openDrawer();
                                                // printWrapped(userDetails.toString());
                                                // Navigator.push(context, MaterialPageRoute(builder: (context)=>RidePage()));
                                              },
                                              child: Icon(
                                                Icons.menu,
                                                size: media.width * 0.05,
                                              ));
                                        }),
                                      ),
                                      (userDetails['low_balance'] == false) &&
                                              (userDetails['role'] ==
                                                      'driver' &&
                                                  (userDetails[
                                                              'vehicle_type_id'] !=
                                                          null ||
                                                      userDetails[
                                                              'vehicle_types']
                                                          .isNotEmpty))
                                          ? Container(
                                              alignment: Alignment.center,
                                              child: InkWell(
                                                onTap: () async {
                                                  // await getUserDetails();
                                                  if (((userDetails[
                                                                  'vehicle_type_id'] !=
                                                              null) ||
                                                          (userDetails[
                                                                  'vehicle_types'] !=
                                                              [])) &&
                                                      userDetails['role'] ==
                                                          'driver') {
                                                    if (locationAllowed ==
                                                            true &&
                                                        serviceEnabled ==
                                                            true) {
                                                      setState(() {
                                                        _isLoading = true;
                                                      });

                                                      var val =
                                                          await driverStatus();
                                                      if (val == 'logout') {
                                                        navigateLogout();
                                                      }
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    } else if (locationAllowed ==
                                                            true &&
                                                        serviceEnabled ==
                                                            false) {
                                                      await geolocator
                                                              .Geolocator
                                                          .getCurrentPosition(
                                                              desiredAccuracy:
                                                                  geolocator
                                                                      .LocationAccuracy
                                                                      .low);
                                                      if (await geolocator
                                                          .GeolocatorPlatform
                                                          .instance
                                                          .isLocationServiceEnabled()) {
                                                        serviceEnabled = true;
                                                        setState(() {
                                                          _isLoading = true;
                                                        });

                                                        var val =
                                                            await driverStatus();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                    } else {
                                                      if (serviceEnabled ==
                                                          true) {
                                                        setState(() {
                                                          makeOnline = true;
                                                        });
                                                      } else {
                                                        await geolocator
                                                                .Geolocator
                                                            .getCurrentPosition(
                                                                desiredAccuracy:
                                                                    geolocator
                                                                        .LocationAccuracy
                                                                        .low);
                                                        setState(() {
                                                          _isLoading = true;
                                                        });
                                                        await getLocs();
                                                        if (serviceEnabled ==
                                                            true) {
                                                          setState(() {
                                                            makeOnline = true;
                                                          });
                                                        }
                                                      }
                                                    }
                                                  }
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.only(
                                                      left: media.width * 0.01,
                                                      right:
                                                          media.width * 0.01),
                                                  height: media.width * 0.08,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            media.width * 0.04),
                                                    color: (userDetails[
                                                                'active'] ==
                                                            false)
                                                        ? offline
                                                        : online,
                                                  ),
                                                  child: (userDetails[
                                                              'active'] ==
                                                          false)
                                                      ? Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_off_duty'],
                                                              // 'offfffffff',
                                                              style: GoogleFonts.roboto(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color:
                                                                      onlineOfflineText),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.01),
                                                              height:
                                                                  media.width *
                                                                      0.07,
                                                              width:
                                                                  media.width *
                                                                      0.07,
                                                              decoration: BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color:
                                                                      onlineOfflineText),
                                                              child: Image.asset(
                                                                  'assets/images/offline.png'),
                                                            )
                                                          ],
                                                        )
                                                      : Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.01),
                                                              height:
                                                                  media.width *
                                                                      0.07,
                                                              width:
                                                                  media.width *
                                                                      0.07,
                                                              decoration: BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color:
                                                                      onlineOfflineText),
                                                              child: Image.asset(
                                                                  'assets/images/online.png'),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_on_duty'],
                                                              // 'onnnnnnnnnnn',
                                                              style: GoogleFonts.roboto(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color:
                                                                      onlineOfflineText),
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            Container(),
                                                          ],
                                                        ),
                                                ),
                                              ),
                                            )
                                          : (userDetails['role'] == 'driver' &&
                                                  (userDetails[
                                                              'vehicle_type_id'] ==
                                                          null &&
                                                      userDetails[
                                                              'vehicle_types']
                                                          .isEmpty))
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                      color: buttonColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10)),
                                                  width: media.width * 0.4,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.025),
                                                  child: Text(
                                                    languages[choosenLanguage][
                                                        'text_no_fleet_assigned'],
                                                    style: GoogleFonts.roboto(
                                                      fontSize: media.width *
                                                          fourteen,
                                                      color: Colors.white,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                )
                                              : (userDetails.isNotEmpty &&
                                                      userDetails[
                                                              'low_balance'] ==
                                                          true)
                                                  ?
                                                  //low balance
                                                  Container(
                                                      decoration: BoxDecoration(
                                                          color: buttonColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10)),
                                                      width: media.width * 0.4,
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.025),
                                                      child: Text(
                                                        userDetails['owner_id'] !=
                                                                null
                                                            ? languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_fleet_diver_low_bal']
                                                            : languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_low_balance'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          color: Colors.white,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    )
                                                  : Container(),
                                      InkWell(
                                          onTap: () {
                                            setState(() {
                                              _choosenDistance =
                                                  choosenDistance;
                                              _selectDistance = true;
                                            });
                                          },
                                          child: Text(
                                            distanceBetween[choosenDistance]
                                                    ['name']
                                                .toString(),
                                            style: GoogleFonts.roboto(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: buttonColor),
                                            textDirection: TextDirection.ltr,
                                          ))
                                    ],
                                  ),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  userDetails['active'] == true &&
                                          rideList.isNotEmpty &&
                                          driverReq.isEmpty
                                      ? Expanded(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              children: rideList
                                                  .asMap()
                                                  .map((key, value) {
                                                    List stops = [];
                                                    if (rideList[key]
                                                            ['trip_stops'] !=
                                                        'null') {
                                                      stops = jsonDecode(
                                                          rideList[key]
                                                              ['trip_stops']);
                                                    }
                                                    return MapEntry(
                                                        key,
                                                        InkWell(
                                                          onTap: () {
                                                            choosenRide.clear();
                                                            choosenRide.add(
                                                                rideList[key]);
                                                            //  tripStops.add({
                                                            //   'address': rideList[key]['drop_address'],
                                                            //   'latitude': rideList[key]['drop_lat'],
                                                            //   'longitude': rideList[key]['drop_lng'],
                                                            //  });
                                                            if (choosenRide[0][
                                                                    'trip_stops'] !=
                                                                'null') {
                                                              tripStops = stops;
                                                            } else {
                                                              tripStops.clear();
                                                            }
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Maps()));
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .all(media
                                                                        .width *
                                                                    0.05),
                                                            margin: EdgeInsets.only(
                                                                bottom: media
                                                                        .width *
                                                                    0.04),
                                                            width: media.width *
                                                                0.9,
                                                            decoration: BoxDecoration(
                                                                color: page,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      blurRadius:
                                                                          2.0,
                                                                      spreadRadius:
                                                                          2.0,
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2))
                                                                ]),
                                                            child: Column(
                                                              children: [
                                                                Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Column(
                                                                      children: [
                                                                        Container(
                                                                          height:
                                                                              media.width * 0.1,
                                                                          width:
                                                                              media.width * 0.1,
                                                                          decoration: BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              image: DecorationImage(image: NetworkImage(rideList[key]['user_img']), fit: BoxFit.cover)),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.05,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.1,
                                                                          child:
                                                                              Text(
                                                                            rideList[key]['user_name'],
                                                                            style:
                                                                                GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.65,
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                languages[choosenLanguage]['text_pick'],
                                                                                // 'pickkkkkkk',
                                                                                style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                              ),
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    choosenRide.clear();
                                                                                    choosenRide.add(rideList[key]);
                                                                                    _cancel = true;
                                                                                  });
                                                                                },
                                                                                child: Text(
                                                                                  languages[choosenLanguage]['text_skip_ride'],
                                                                                  // 'skippppppppp',
                                                                                  style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600, color: Colors.red),
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.025,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.65,
                                                                          child:
                                                                              Text(
                                                                            rideList[key]['pick_address'],
                                                                            style:
                                                                                GoogleFonts.roboto(
                                                                              fontSize: media.width * twelve,
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ),
                                                                        (stops.isEmpty)
                                                                            ? Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  SizedBox(
                                                                                    height: media.width * 0.025,
                                                                                  ),
                                                                                  Text(
                                                                                    languages[choosenLanguage]['text_drop'],
                                                                                    // 'droppppppp',
                                                                                    style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: media.width * 0.025,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.65,
                                                                                    child: Text(
                                                                                      rideList[key]['drop_address'],
                                                                                      style: GoogleFonts.roboto(
                                                                                        fontSize: media.width * twelve,
                                                                                      ),
                                                                                      maxLines: 1,
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                              )
                                                                            : Column(
                                                                                children: stops
                                                                                    .asMap()
                                                                                    .map((key, value) {
                                                                                      return MapEntry(
                                                                                          key,
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              if (key == 0)
                                                                                                SizedBox(
                                                                                                  height: media.width * 0.025,
                                                                                                ),
                                                                                              if (key == 0)
                                                                                                Text(
                                                                                                  languages[choosenLanguage]['text_drop'],
                                                                                                  // 'droppppppppp',
                                                                                                  style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                                ),
                                                                                              SizedBox(
                                                                                                height: media.width * 0.025,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.65,
                                                                                                child: Text(
                                                                                                  stops[key]['address'],
                                                                                                  style: GoogleFonts.roboto(
                                                                                                    fontSize: media.width * twelve,
                                                                                                  ),
                                                                                                  maxLines: 1,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ));
                                                                                    })
                                                                                    .values
                                                                                    .toList(),
                                                                              ),
                                                                        if (rideList[key]['goods'] !=
                                                                            'null')
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              SizedBox(
                                                                                height: media.width * 0.025,
                                                                              ),
                                                                              Text(
                                                                                languages[choosenLanguage]['text_goods_type'],
                                                                                style: GoogleFonts.roboto(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.025,
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.65,
                                                                                child: Text(
                                                                                  rideList[key]['goods'],
                                                                                  style: GoogleFonts.roboto(
                                                                                    fontSize: media.width * twelve,
                                                                                  ),
                                                                                  maxLines: 2,
                                                                                ),
                                                                              )
                                                                            ],
                                                                          ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.025,
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  child: Text(
                                                                    '${rideList[key]['currency']} ${rideList[key]['price']}',
                                                                    style: GoogleFonts.roboto(
                                                                        fontSize:
                                                                            media.width *
                                                                                sixteen,
                                                                        fontWeight:
                                                                            FontWeight.w600),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        ));
                                                  })
                                                  .values
                                                  .toList(),
                                            ),
                                          ),
                                        )
                                      : (userDetails['active'] == false)
                                          ? Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: media.width * 0.7,
                                                    height: media.width * 0.7,
                                                    child: Image.asset(
                                                      'assets/images/offline_image.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.9,
                                                    child: Text(
                                                      languages[choosenLanguage]
                                                          [
                                                          'text_you_are_offduty'],
                                                      // 'offffff buuuutyyyyy',
                                                      style: GoogleFonts.roboto(
                                                        fontSize: media.width *
                                                            sixteen,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            )
                                          : (rideList.isEmpty)
                                              ? Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.7,
                                                        height:
                                                            media.width * 0.7,
                                                        child: Image.asset(
                                                          'assets/images/no_ride.png',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.9,
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_no_ride_in_area'],
                                                          // 'no rideeeeeeee in yoooouuuu_area',
                                                          style: GoogleFonts
                                                              .roboto(
                                                            fontSize:
                                                                media.width *
                                                                    sixteen,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : Container(),
                                ],
                              ),
                            ),

                            //delete account
                            (deleteAccount == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                    height: media.height * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            deleteAccount =
                                                                false;
                                                          });
                                                        },
                                                        child: const Icon(Icons
                                                            .cancel_outlined))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page),
                                            child: Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_delete_confirm'],
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        deleteAccount = false;
                                                        _isLoading = true;
                                                      });
                                                      var result =
                                                          await userDelete();
                                                      if (result == 'success') {
                                                        setState(() {
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          Login()),
                                                              (route) => false);
                                                          userDetails.clear();
                                                        });
                                                      } else if (result ==
                                                          'logout') {
                                                        navigateLogout();
                                                      } else {
                                                        setState(() {
                                                          _isLoading = false;
                                                          deleteAccount = true;
                                                        });
                                                      }
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                : Container(),

                            //logout popup
                            (logout == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                    height: media.height * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            logout = false;
                                                          });
                                                        },
                                                        child: const Icon(Icons
                                                            .cancel_outlined))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page),
                                            child: Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_confirmlogout'],
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        _isLoading = true;
                                                        logout = false;
                                                      });
                                                      var result =
                                                          await userLogout();
                                                      if (result == 'success') {
                                                        setState(() {
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const SignupMethod()),
                                                              (route) => false);
                                                          userDetails.clear();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          logout = true;
                                                        });
                                                      }
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ))
                                : Container(),

                            if (_cancel == true)
                              Positioned(
                                  child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: media.width * 0.9,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                              height: media.height * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: page),
                                              child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _cancel = false;
                                                    });
                                                  },
                                                  child: const Icon(
                                                      Icons.cancel_outlined))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_cancel_confirmation'],
                                            // 'yyygghjhgjhgjhghgh',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () async {
                                                setState(() {
                                                  _isLoading = true;
                                                });
                                                try {
                                                  await FirebaseDatabase
                                                      .instance
                                                      .ref()
                                                      .child(
                                                          'bid-meta/${choosenRide[0]["request_id"]}/drivers/${userDetails["id"]}')
                                                      .update({
                                                    'driver_id':
                                                        userDetails['id'],
                                                    'price': choosenRide[0]
                                                            ["price"]
                                                        .toString(),
                                                    'driver_name':
                                                        userDetails['name'],
                                                    'driver_img': userDetails[
                                                        'profile_picture'],
                                                    'bid_time':
                                                        ServerValue.timestamp,
                                                    'is_rejected': 'by_driver'
                                                  });

                                                  // Navigator.pop(context);
                                                } catch (e) {
                                                  debugPrint(e.toString());
                                                }
                                                setState(() {
                                                  _cancel = false;
                                                  _isLoading = false;
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_confirm'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )),

                            //waiting for ride to accept by customer
                            if (waitingList.isNotEmpty)
                              Positioned(
                                  child: ValueListenableBuilder(
                                      valueListenable: valueNotifierTimer.value,
                                      builder: (context, value, child) {
                                        var val = DateTime.now()
                                            .difference(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    waitingList[0]['drivers'][
                                                            '${userDetails["id"]}']
                                                        ['bid_time']))
                                            .inSeconds;
                                        if (int.parse(val.toString()) >=
                                            (int.parse(userDetails[
                                                        'maximum_time_for_find_drivers_for_bitting_ride']
                                                    .toString()) +
                                                5)) {
                                          FirebaseDatabase.instance
                                              .ref()
                                              .child(
                                                  'bid-meta/${waitingList[0]["request_id"]}/drivers/${userDetails["id"]}')
                                              .update(
                                                  {"is_rejected": 'by_user'});
                                        }
                                        return Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                        width:
                                                            media.width * 0.7,
                                                        child: Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_waiting_for_user'],
                                                          // 'waiting for useeeerrrr',
                                                          style: GoogleFonts
                                                              .roboto(
                                                                  fontSize: media
                                                                          .width *
                                                                      sixteen,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: page),
                                                          textAlign:
                                                              TextAlign.center,
                                                        )),
                                                  ],
                                                ),
                                              ),
                                              if (waitingList.isNotEmpty)
                                                Container(
                                                  width: media.width * 1,
                                                  decoration: BoxDecoration(
                                                      color: page,
                                                      //  borderRadius: BorderRadius.only(topRight:Radius.circular(10), topLeft: Radius.circular(10)),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2.0,
                                                            spreadRadius: 2.0,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2))
                                                      ]),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        width: (media.width *
                                                                1 /
                                                                (int.parse(userDetails[
                                                                            'maximum_time_for_find_drivers_for_bitting_ride']
                                                                        .toString()) +
                                                                    5)) *
                                                            ((int.parse(userDetails[
                                                                            'maximum_time_for_find_drivers_for_bitting_ride']
                                                                        .toString()) +
                                                                    5) -
                                                                double.parse(val
                                                                    .toString())),
                                                        height: 5,
                                                        color: buttonColor,
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.05),
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Column(
                                                                  children: [
                                                                    Container(
                                                                      height:
                                                                          media.width *
                                                                              0.1,
                                                                      width: media
                                                                              .width *
                                                                          0.1,
                                                                      decoration: BoxDecoration(
                                                                          shape: BoxShape
                                                                              .circle,
                                                                          image: DecorationImage(
                                                                              image: NetworkImage(waitingList[0]['user_img']),
                                                                              fit: BoxFit.cover)),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.1,
                                                                      child:
                                                                          Text(
                                                                        waitingList[0]
                                                                            [
                                                                            'user_name'],
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width *
                                                                                fourteen,
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    )
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.025,
                                                                ),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.75,
                                                                      child:
                                                                          Text(
                                                                        // languages[
                                                                        //         choosenLanguage]
                                                                        //     [
                                                                        //     'text_pick']
                                                                        'pickkkk',
                                                                        style: GoogleFonts.roboto(
                                                                            fontSize: media.width *
                                                                                fourteen,
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.65,
                                                                      child:
                                                                          Text(
                                                                        waitingList[0]
                                                                            [
                                                                            'pick_address'],
                                                                        style: GoogleFonts
                                                                            .roboto(
                                                                          fontSize:
                                                                              media.width * twelve,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    Text(
                                                                      languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_drop'],
                                                                      style: GoogleFonts.roboto(
                                                                          fontSize: media.width *
                                                                              fourteen,
                                                                          fontWeight:
                                                                              FontWeight.w600),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.65,
                                                                      child:
                                                                          Text(
                                                                        waitingList[0]
                                                                            [
                                                                            'drop_address'],
                                                                        style: GoogleFonts
                                                                            .roboto(
                                                                          fontSize:
                                                                              media.width * twelve,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                      ),
                                                                    )
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Text(
                                                                '${waitingList[0]['currency']} ${waitingList[0]['drivers']['${userDetails["id"]}']['price']}',
                                                                style: GoogleFonts.roboto(
                                                                    fontSize: media
                                                                            .width *
                                                                        sixteen,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                            ],
                                          ),
                                        );
                                      })),

                            //select distance
                            (_selectDistance == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                    height: media.height * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: page),
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _selectDistance =
                                                                false;
                                                          });
                                                        },
                                                        child: const Icon(Icons
                                                            .cancel_outlined))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            width: media.width * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page),
                                            child: Column(
                                              children: [
                                                Text(
                                                  languages[choosenLanguage]
                                                      ['text_distance_between'],
                                                  // 'distebbbjhjh bjhhjg',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.roboto(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Column(
                                                  children: distanceBetween
                                                      .asMap()
                                                      .map((i, value) {
                                                        return MapEntry(
                                                          i,
                                                          InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                _choosenDistance =
                                                                    i;
                                                              });
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Container(
                                                                  height: media
                                                                          .height *
                                                                      0.05,
                                                                  width: media
                                                                          .width *
                                                                      0.05,
                                                                  decoration: BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      border: Border.all(
                                                                          color: Colors
                                                                              .black,
                                                                          width:
                                                                              1.2)),
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child: (_choosenDistance ==
                                                                          i)
                                                                      ? Container(
                                                                          height:
                                                                              media.width * 0.03,
                                                                          width:
                                                                              media.width * 0.03,
                                                                          decoration:
                                                                              const BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        )
                                                                      : Container(),
                                                                ),
                                                                SizedBox(
                                                                  width: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                Text(
                                                                  distanceBetween[
                                                                              i]
                                                                          [
                                                                          'name']
                                                                      .toString(),
                                                                  textDirection:
                                                                      TextDirection
                                                                          .ltr,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                      })
                                                      .values
                                                      .toList(),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.025,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        choosenDistance =
                                                            _choosenDistance;
                                                        _selectDistance = false;
                                                        pref.setString(
                                                            'choosenDistance',
                                                            choosenDistance
                                                                .toString());

                                                        rideStart?.cancel();
                                                        rideStart = null;
                                                        rideRequest();
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_confirm'])
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                : Container(),

                            (updateAvailable == true)
                                ? Positioned(
                                    top: 0,
                                    child: Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      color:
                                          Colors.transparent.withOpacity(0.6),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                              width: media.width * 0.9,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: page,
                                              ),
                                              child: Column(
                                                children: [
                                                  SizedBox(
                                                      width: media.width * 0.8,
                                                      child: Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_update_available'],
                                                        style:
                                                            GoogleFonts.roboto(
                                                                fontSize: media
                                                                        .width *
                                                                    sixteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      )),
                                                  SizedBox(
                                                    height: media.width * 0.05,
                                                  ),
                                                  Button(
                                                      onTap: () async {
                                                        if (platform ==
                                                            TargetPlatform
                                                                .android) {
                                                          openBrowser(
                                                              'https://play.google.com/store/apps/details?id=${package.packageName}');
                                                        } else {
                                                          setState(() {
                                                            _isLoading = true;
                                                          });
                                                          var response = await http
                                                              .get(Uri.parse(
                                                                  'http://itunes.apple.com/lookup?bundleId=${package.packageName}'));
                                                          if (response
                                                                  .statusCode ==
                                                              200) {
                                                            openBrowser(jsonDecode(
                                                                        response
                                                                            .body)[
                                                                    'results'][0]
                                                                [
                                                                'trackViewUrl']);

                                                            // printWrapped(jsonDecode(response.body)['results'][0]['trackViewUrl']);
                                                          }

                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                        }
                                                      },
                                                      text: 'Update')
                                                ],
                                              ))
                                        ],
                                      ),
                                    ))
                                : Container(),

                            //loader
                            (_isLoading == true)
                                ? const Positioned(top: 0, child: Loading())
                                : Container(),
                          ],
                        ),
                      ),
                    );
                  })
              : (state == '1')
                  ? Container(
                      padding: EdgeInsets.all(media.width * 0.05),
                      width: media.width * 0.6,
                      height: media.width * 0.3,
                      decoration: BoxDecoration(
                          color: page,
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 5,
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2)
                          ],
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languages[choosenLanguage]['text_enable_location'],
                            style: GoogleFonts.roboto(
                                fontSize: media.width * sixteen,
                                color: textColor,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  state = '';
                                });
                                getLocs();
                              },
                              child: Text(
                                languages[choosenLanguage]['text_ok'],
                                style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.bold,
                                    fontSize: media.width * twenty,
                                    color: buttonColor),
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : (state == '2')
                      ? Container(
                          height: media.height * 1,
                          width: media.width * 1,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: media.height * 0.31,
                                child: Image.asset(
                                  'assets/images/allow_location_permission.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Text(
                                languages[choosenLanguage]['text_trustedtaxi'],
                                style: GoogleFonts.roboto(
                                    fontSize: media.width * eighteen,
                                    fontWeight: FontWeight.w600),
                              ),
                              SizedBox(
                                height: media.width * 0.025,
                              ),
                              Text(
                                languages[choosenLanguage]
                                    ['text_allowpermission1'],
                                style: GoogleFonts.roboto(
                                  fontSize: media.width * fourteen,
                                ),
                              ),
                              Text(
                                languages[choosenLanguage]
                                    ['text_allowpermission2'],
                                style: GoogleFonts.roboto(
                                  fontSize: media.width * fourteen,
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.05,
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(media.width * 0.05,
                                    0, media.width * 0.05, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.075,
                                        child: const Icon(
                                            Icons.location_on_outlined)),
                                    SizedBox(
                                      width: media.width * 0.025,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_loc_permission'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: media.width * 0.02,
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(media.width * 0.05,
                                    0, media.width * 0.05, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width: media.width * 0.075,
                                        child: const Icon(
                                            Icons.location_on_outlined)),
                                    SizedBox(
                                      width: media.width * 0.025,
                                    ),
                                    SizedBox(
                                      width: media.width * 0.8,
                                      child: Text(
                                        languages[choosenLanguage]
                                            ['text_background_permission'],
                                        style: GoogleFonts.roboto(
                                            fontSize: media.width * fourteen,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  padding: EdgeInsets.all(media.width * 0.05),
                                  child: Button(
                                      onTap: () async {
                                        getLocationPermission();
                                      },
                                      text: languages[choosenLanguage]
                                          ['text_continue']))
                            ],
                          ),
                        )
                      : Container()),
    );
  }
}
