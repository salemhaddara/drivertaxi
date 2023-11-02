import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tagxibiddingdriver/styles/styles.dart';

class photoHolder extends StatelessWidget {
  double width;
  double height;
  String title;
  String buttonTitle;
  Function onPhotoScanned;
  Function onScanTapped;
  bool photoVisible;
  XFile? photo;
  Color textcolortitle;
  String lottieStatus;
  bool lottieRepeat;
  photoHolder(
      {super.key,
      required this.width,
      required this.height,
      required this.title,
      required this.buttonTitle,
      required this.onPhotoScanned,
      required this.photoVisible,
      required this.photo,
      required this.onScanTapped,
      required this.textcolortitle,
      required this.lottieStatus,
      required this.lottieRepeat});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(children: [
          SizedBox(
            height: 50,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: width * fifteen,
                      color: textcolortitle,
                    ),
                  ),
                ),
                Visibility(
                    visible: lottieStatus.isNotEmpty,
                    child: Expanded(
                      flex: 1,
                      child: LottieBuilder.asset(
                        lottieStatus,
                        repeat: lottieRepeat,
                        animate: true,
                      ),
                    ))
              ],
            ),
          ),
          Expanded(
              child: Column(
            children: [
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                if (photoVisible) {
                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: SizedBox(
                            height: (constraints.maxHeight),
                            width: (constraints.maxWidth),
                            child: Image.file(
                              File(photo!.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Material(
                            elevation: 10,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(25)),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                              child: InkWell(
                                onTap: () {
                                  onScanTapped();
                                },
                                child:
                                    SvgPicture.asset('assets/images/scan.svg'),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                } else {
                  return Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: (constraints.maxHeight) / 4,
                      width: (constraints.maxWidth) / 3,
                      child: InkWell(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          onTap: () async {
                            onScanTapped();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/images/scan.svg'),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Scan',
                                style: GoogleFonts.roboto(
                                    fontSize: width * fifteen,
                                    color: buttonColor,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          )),
                    ),
                  );
                }
              }))
            ],
          ))
        ]),
      ),
    );
  }
}
