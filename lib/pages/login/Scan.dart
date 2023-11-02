import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linear_progress_bar/linear_progress_bar.dart';
// import 'package:tagxibiddingdriver/pages/login/get_started.dart';
import 'package:tagxibiddingdriver/pages/login/login.dart';
// import 'package:tagxibiddingdriver/pages/login/otp_page.dart';
import 'package:tagxibiddingdriver/widgets/photoHolder.dart';
import 'package:http/http.dart' as http;

import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translation/translation.dart';

import '../../widgets/widgets.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Map<int, Color> listColor = {
    0: buttonColor,
    1: buttonColor,
    2: buttonColor,
    3: buttonColor,
    4: buttonColor,
    5: buttonColor
  };
  Map<String, String> informations = {};
  Map<String, XFile> photos = {};
  Map<int, String> lotties = {};

  String dlf = languages[choosenLanguage]['driverlicensefront'];
  String dlb = languages[choosenLanguage]['driverlicenseback'];
  String dlcf = languages[choosenLanguage]['driveridentitycardfront'];
  String dlcb = languages[choosenLanguage]['driveridentitycardback'];
  String clcf = languages[choosenLanguage]['carlicensecardfront'];
  String clcb = languages[choosenLanguage]['carlicensecardback'];
  final ScrollController _scrollController = ScrollController();
  bool isWorking = false;
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    if (photos.isNotEmpty && photos.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
    return Material(
        child: SingleChildScrollView(
      child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Stack(children: [
            Container(
              padding: EdgeInsets.only(
                  left: media.width * 0.03, right: media.width * 0.03),
              height: media.height * 1,
              width: media.width * 1,
              color: page,
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.bottomLeft,
                    height: media.height * 0.02,
                    width: media.width * 1,
                    color: topBar,
                  ),
                  SizedBox(
                    height: media.height * 0.04,
                  ),
                  SizedBox(
                      width: media.width,
                      child: Text(
                        languages[choosenLanguage]['scanInfos'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                            fontSize: media.width * twentysix,
                            color: textColor,
                            fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(
                    height: 10,
                  ),
                  LinearProgressBar(
                    maxSteps: 7,
                    progressType: LinearProgressBar.progressTypeLinear,
                    currentStep: photos.length + 1,
                    progressColor: buttonColor,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                      width: media.width * 1,
                      child: Text(
                        languages[choosenLanguage]
                            ['Pleasescanthefollowingpapers'],
                        style: GoogleFonts.roboto(
                            fontSize: media.width * twenty,
                            color: textColor,
                            fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 10),
                  SizedBox(
                      width: media.width * 1,
                      child: Text(
                        languages[choosenLanguage]
                            ['thiswillspeedupthesignupprocess'],
                        style: GoogleFonts.roboto(
                          fontSize: media.width * fourteen,
                          color: textColor,
                        ),
                      )),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      children: [
                        const SizedBox(height: 20),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: dlf,
                          buttonTitle: 'nice',
                          onPhotoScanned: () {},
                          photo: photos['dlf'],
                          photoVisible: photos.containsKey('dlf'),
                          textcolortitle: listColor[0]!,
                          lottieStatus: lotties[0] ?? '',
                          lottieRepeat: true,
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(0, 'assets/scanning.json');
                                setState(() {});
                                dlf = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['driverlicensefront'],
                                    0,
                                    photo,
                                    'dlf',
                                    'رخصه قياده خاصه');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: dlb,
                          buttonTitle: 'nice',
                          lottieStatus: lotties[1] ?? '',
                          lottieRepeat: true,
                          textcolortitle: listColor[1]!,
                          onPhotoScanned: () {},
                          photo: photos['dlb'],
                          photoVisible: photos.containsKey('dlb'),
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(1, 'assets/scanning.json');
                                setState(() {});
                                dlb = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['driverlicenseback'],
                                    1,
                                    photo,
                                    'dlb',
                                    'وزارة الداخلية');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        Divider(
                          height: 3,
                          color: textColor,
                        ),
                        const SizedBox(height: 15),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: dlcf,
                          lottieStatus: lotties[2] ?? '',
                          lottieRepeat: true,
                          buttonTitle: 'nice',
                          textcolortitle: listColor[2]!,
                          onPhotoScanned: () {},
                          photo: photos['dlcf'],
                          photoVisible: photos.containsKey('dlcf'),
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(2, 'assets/scanning.json');
                                setState(() {});
                                dlcf = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['driveridentitycardfront'],
                                    2,
                                    photo,
                                    'dlcf',
                                    'بطاقة تحقيق الشخصية');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: dlcb,
                          lottieStatus: lotties[3] ?? '',
                          lottieRepeat: true,
                          buttonTitle: 'nice',
                          textcolortitle: listColor[3]!,
                          onPhotoScanned: () {},
                          photo: photos['dlcb'],
                          photoVisible: photos.containsKey('dlcb'),
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(3, 'assets/scanning.json');
                                setState(() {});
                                dlcb = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['driveridentitycardback'],
                                    3,
                                    photo,
                                    'dlcb',
                                    'البطاقة سارية حتى');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 15),
                        Divider(
                          height: 3,
                          color: textColor,
                        ),
                        const SizedBox(height: 15),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: clcf,
                          lottieStatus: lotties[4] ?? '',
                          lottieRepeat: true,
                          buttonTitle: 'nice',
                          textcolortitle: listColor[4]!,
                          onPhotoScanned: () {},
                          photo: photos['clcf'],
                          photoVisible: photos.containsKey('clcf'),
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(4, 'assets/scanning.json');
                                setState(() {});
                                clcf = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['carlicensecardfront'],
                                    4,
                                    photo,
                                    'clcf',
                                    'نهاية الترخيص');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        photoHolder(
                          width: media.width * 1,
                          height: media.width * 0.5,
                          title: clcb,
                          lottieStatus: lotties[5] ?? '',
                          lottieRepeat: true,
                          buttonTitle: 'nice',
                          textcolortitle: listColor[5]!,
                          onPhotoScanned: () {},
                          photo: photos['clcb'],
                          photoVisible: photos.containsKey('clcb'),
                          onScanTapped: () async {
                            if (!isWorking) {
                              XFile? photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) {
                                //START LOADING
                                updatelottie(5, 'assets/scanning.json');
                                setState(() {});
                                clcb = await performImageRecognition(
                                    File(photo.path),
                                    languages[choosenLanguage]
                                        ['carlicensecardback'],
                                    5,
                                    photo,
                                    'clcb',
                                    'تاريخ الفحص');

                                setState(() {});
                              }
                            } else {
                              ShowToast();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Visibility(
                          visible: photos.length == 6,
                          child: Button(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Login(
                                            data: [photos, informations])));
                              },
                              text: languages[choosenLanguage]
                                  ['text_continue']),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ])),
    ));
  }

  Future<bool> isThePaper(XFile picture, String requiredtext) async {
    InputImage image = InputImage.fromFile(File(picture.path));
    final RecognizedText recognizedtext =
        await textRecognizer.processImage(image);
    String text = recognizedtext.text;
    if (text.contains(requiredtext)) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> performImageRecognition(File imageFile, String oldTitle,
      int index, XFile photo, String key, String identification) async {
    //REQUEST OCR FROM VISION API
    const apiKey = 'AIzaSyAeUivh5Ao6aN63K2He-qI4HxHIpZCPSmQ';
    final apiUrl = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
    final imageBytes = await imageFile.readAsBytes();
    final requestJson = {
      'requests': [
        {
          'image': {'content': base64Encode(imageBytes)},
          'features': [
            {'type': 'TEXT_DETECTION'}
          ],
        },
      ],
    };
    isWorking = true;

    //GETTING THE RESPOMSE FROM VISION API
    final response = await http.post(
      apiUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestJson),
    );

    //IF RESPONSE OK
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseMap = json.decode(response.body);
      final List<dynamic>? textAnnotations =
          (responseMap['responses'][0]['textAnnotations']);

      //IF TEXT NOT EQUAL TO NULL
      if (textAnnotations != null && textAnnotations.isNotEmpty) {
        final String recognizedText = textAnnotations[0]['description'];

        if (recognizedText.contains(identification)) {
          updatelottie(index, 'assets/done.json');

          print('Recognized Text: $recognizedText');
          listColor.update(index, (value) => buttonColor);
          addPhotoIfValid(key, photo);
          addPaperinfo(key, recognizedText);
          isWorking = false;
          return oldTitle;
        } else {
          updatelottie(index, 'assets/notvalid.json');
          listColor.update(index, (value) => Colors.red);
          isWorking = false;
          return '$oldTitle ( Not Valid or Not Clear)';
        }
      }

      //HANDLE NO TEXT CASE
      else {
        updatelottie(index, 'assets/notvalid.json');
        listColor.update(index, (value) => Colors.red);
        isWorking = false;
        return '$oldTitle ( Not Valid or Not Clear)';
      }
    }

    //Handle ERROR HERE
    else {
      updatelottie(index, 'assets/notvalid.json');
      isWorking = false;
      listColor.update(index, (value) => Colors.red);
      return '$oldTitle ( Check Your Internet Connection)';
    }
  }

  void addPhotoIfValid(String key, XFile photo) {
    if (!photos.containsKey(key)) {
      photos.putIfAbsent(key, () => photo);
    } else {
      photos.update(key, (value) => photo);
    }
  }

  void addPaperinfo(String paperkey, String info) {
    if (!informations.containsKey(paperkey)) {
      informations.putIfAbsent(paperkey, () => info);
    } else {
      informations.update(paperkey, (value) => info);
    }
  }

  void updatelottie(int key, String lottie) {
    if (!lotties.containsKey(key)) {
      lotties.putIfAbsent(key, () => lottie);
    } else {
      lotties.update(key, (value) => lottie);
    }
  }

  void ShowToast({String message = 'Wait till Scanning Complete '}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: buttonColor,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
