import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:raka/colors.dart';

void main() {
  //WidgetsFlutterBinding.ensureInitialized();
  //MobileAds.instance.initialize();
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.mainColor, width: 2),
            ),
          ),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.mainColor, //thereby
          ),
          focusColor: AppColors.mainColor,
          colorScheme:
              ColorScheme.fromSwatch().copyWith(secondary: AppColors.mainColor),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.mainColor,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.primaryColor,
        appBar: AppBar(
          title: const Text('เปรียบเทียบราคา'),
          actions: <Widget>[
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: Colors.white,
              ),
              color: Colors.white,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(
                      child: Text(
                        'เกี่ยวกับ',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero).then((value) {
                          showAlertDialog(context);
                        });
                      }),
                ];
              },
            ),
          ],
        ),
        body: HomeWidget());
  }
}

class HomeWidget extends StatefulWidget {
  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  InterstitialAd? _interstitialAd;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // TODO: replace this test ad unit with your own ad unit.
  final adbannerUnitId = Platform.isAndroid
      ? 'ca-app-pub-8467206635180635/1379097403'
      : 'ca-app-pub-8467206635180635/1379097403';

  final adinterUnitId = Platform.isAndroid
      ? 'ca-app-pub-8467206635180635/4815779532'
      : 'ca-app-pub-8467206635180635/4815779532';
  int itemCount = 2;
  bool visblefromcompare = true;
  bool visbleTextrage = false;
  List<String> listcheapsort = [];
  List<List<TextEditingController>> controllersList = [];
  ValueNotifier<String> compareText = ValueNotifier<String>("แบบที่-ถูกกว่า");
  ValueNotifier<String> compareCheaperPriceText = ValueNotifier<String>("0");
  ValueNotifier<String> comparePercentageText = ValueNotifier<String>("0");
  ValueNotifier<String> unitsaveText = ValueNotifier<String>("0");
  ValueNotifier<String> saveMoneyText = ValueNotifier<String>("0");

  void loadAdInterstitalad() {
    InterstitialAd.load(
        adUnitId: adinterUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // Called when an ad is successfully received.
          onAdLoaded: (ad) {
            setState(() {
              _interstitialAd = ad;
            });

            ad.fullScreenContentCallback = FullScreenContentCallback(
                // Called when the ad showed the full screen content.
                onAdShowedFullScreenContent: (ad) {},
                // Called when an impression occurs on the ad.
                onAdImpression: (ad) {},
                // Called when the ad failed to show full screen content.
                onAdFailedToShowFullScreenContent: (ad, err) {
                  // Dispose the ad here to free resources.
                },
                // Called when the ad dismissed full screen content.
                onAdDismissedFullScreenContent: (ad) {
                  // Dispose the ad here to free resources.
                  loadAdInterstitalad();
                },
                // Called when a click is recorded for an ad.
                onAdClicked: (ad) {});

            debugPrint('$ad loaded.');
            // Keep a reference to the ad so you can show it later.
            _interstitialAd = ad;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));
  }

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adbannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {},
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {},
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {},
      ),
    )..load();
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      return;
    }
    _interstitialAd!.show();
  }

  void _clearAllEdittext() {
    setState(() {
      for (List<TextEditingController> controllers in controllersList) {
        for (TextEditingController controller in controllers) {
          controller.clear();
          resetCompare();
        }
      }
      newControllersList(itemCount);
    });
  }

  void resetCompare() {
    compareText.value = "แบบที่-ถูกกว่า";
    compareCheaperPriceText.value = "0";
    comparePercentageText.value = "0";
    unitsaveText.value = "0";
    saveMoneyText.value = "0";
    setState(() {
      listcheapsort.clear();
    });
  }

  void updateListCheapsort() {
    double minUnitPrice = double.infinity;
    int cheaperItemIndex = 0;

    for (int i = 0; i < controllersList.length; i++) {
      try {
        double unitPrice = double.parse(controllersList[i][4].text);
        if (unitPrice < minUnitPrice) {
          minUnitPrice = unitPrice;
          cheaperItemIndex = i + 1;
          int index = 0;
          index = i;
        }
        // ทำงานกับ unitPrice ที่ได้แปลงเป็น double ได้ตรงนี้
      } catch (FormatException) {
        // รับทราบว่ามีข้อผิดพลาดในการแปลงข้อมูลเป็น double
        print("ข้อมูลไม่ถูกต้อง");
      }
    }

    // คัดลอก controllersList ไปยัง sortedList เพื่อป้องกันการแก้ไขข้อมูลต้นฉบับ
    List<List<TextEditingController>> sortedList = List.from(controllersList);

    // เรียงลำดับ sortedList ตามราคาที่ถูกที่สุดจากน้อยไปมาก
    try {
      sortedList.sort(
          (a, b) => double.parse(a[4].text).compareTo(double.parse(b[4].text)));
    } catch (FormatException) {
      // รับทราบว่ามีข้อผิดพลาดในการแปลงข้อมูลเป็น double
      print("ข้อมูลไม่ถูกต้อง");
    }

    // เรียงลำดับ listcheapsort ตามลำดับของ sortedList
    setState(() {
      listcheapsort = sortedList.map((item) => item[0].text).toList();
      String itemNameHint = listcheapsort[0];
      compareText.value = itemNameHint + " " + " ถูกกว่า";
    });

    // อัพเดตข้อความเปรียบเทียบ
  }

  void calculateCompareAll() {
    if (controllersList.length > 2) {
      updateListCheapsort();
    } else {
      calculateUnitPrice();
      try {
        double unitPrice1 =
            double.parse(controllersList[0][4].text); // ราคาหน่วยของรายการแรก
        double unitPrice2 = double.parse(
            controllersList[1][4].text); // ราคาหน่วยของรายการที่สอง
        String unitsave = "0";
        String cheaperOption;
        if (unitPrice1 < unitPrice2) {
          cheaperOption = controllersList[0][0].text + " ถูกกว่า";
          unitsave = controllersList[0][2].text;
        } else if (unitPrice1 > unitPrice2) {
          cheaperOption = controllersList[1][0].text + " ถูกกว่า";
          unitsave = controllersList[1][2].text;
        } else {
          cheaperOption = "ทั้งสองแบบเท่ากัน";
        }

// 2. หาว่าถูกกว่าหน่วยละกี่บาท
        double cheaperPrice = unitPrice1 < unitPrice2
            ? unitPrice2 - unitPrice1
            : unitPrice1 - unitPrice2;

        //3. หาว่าถ้าซื้อ quantity ของแบบที่ถูกกว่าจะประหยัดกี่บาท

        double quantity1 =
            double.parse(controllersList[0][2].text); // ปริมาณของแบบที่ 1
        double quantity2 =
            double.parse(controllersList[1][2].text); // ปริมาณของแบบที่ 2

// 4. หาว่าถูกกว่ากี่เปอร์เซ็นต์
        double cheaperPercentage;
        double saving;
        if (unitPrice1 > unitPrice2) {
          saving = (unitPrice1 - unitPrice2) * quantity1;
          cheaperPercentage = ((unitPrice1 - unitPrice2) / unitPrice1) * 100;
        } else {
          saving = (unitPrice2 - unitPrice1) * quantity2;
          cheaperPercentage = ((unitPrice2 - unitPrice1) / unitPrice2) * 100;
        }

        compareText.value = cheaperOption;
        compareCheaperPriceText.value =
            cheaperPrice.toStringAsFixed(4).toString();
        comparePercentageText.value =
            cheaperPercentage.toStringAsFixed(3).toString();
        unitsaveText.value = unitsave.toString();
        saveMoneyText.value = saving.truncate().toStringAsFixed(2).toString();
      } catch (FormatException) {
        // รับทราบว่ามีข้อผิดพลาดในการแปลงข้อมูลเป็น double
        print("ข้อมูลไม่ถูกต้อง");
      }

// 1. หาว่าแบบที่ 1 หรือ 2 ถูกกว่า
    }
  }

  bool isPriceAndQuantityFilled() {
    // ลูปเพื่อเข้าถึง controllersList ของแต่ละรายการ
    for (List<TextEditingController> controllers in controllersList) {
      // ตรวจสอบว่า controller ของ price และ quantity ในรายการนี้มีค่าว่างเปล่าหรือไม่
      if (controllers[1].text.isEmpty || controllers[2].text.isEmpty) {
        // ถ้ามี controller ของ price หรือ quantity ในรายการใดรายการหนึ่งเป็นค่าว่างเปล่า จะ return false
        return false;
      }
    }
    return true;
  }

  bool isPriceAndQuantityFilledLast() {
    if (controllersList.isEmpty) {
      return false; // ไม่มีรายการใน controllersList
    }

    int lastItemIndex = controllersList.length - 1; // ดัชนีของรายการล่าสุด
    List<TextEditingController> lastItemControllers =
        controllersList[lastItemIndex];

    // ตรวจสอบว่า controllers ของ price และ quantity ในรายการล่าสุดมีค่าว่างเปล่าหรือไม่
    if (lastItemControllers.length > 2) {
      return lastItemControllers[1].text.isNotEmpty &&
          lastItemControllers[2].text.isNotEmpty;
    } else {
      return false; // ไม่มี controllers ใน index 1 และ index 2 ในรายการล่าสุด
    }
  }

  void calculateUnitPrice() {
    // ลูปเพื่อเข้าถึง controllersList ของแต่ละรายการ
    for (List<TextEditingController> controllers in controllersList) {
      // ตรวจสอบว่า controller ของ price และ quantity ในแต่ละรายการมีข้อมูล
      if (controllers[1].text.isNotEmpty && controllers[2].text.isNotEmpty) {
        // ดึงค่า price และ quantity จาก controllers
        double price = double.parse(controllers[1].text);
        double quantity = double.parse(controllers[2].text);

        // คำนวณ unitPrice โดยหาร price กับ quantity
        double unitPrice = price / quantity;

        // ตรวจสอบว่ามีการกรอกข้อมูลใน volume หรือไม่
        if (controllers[3].text.isNotEmpty) {
          // หากมีการกรอก volume ให้นำผลลัพธ์ที่ได้มาคูณกับ volume
          double volume = double.parse(controllers[3].text);
          unitPrice *= volume;
        }

        // แสดงผลลัพธ์ที่ unitPrice TextField
        controllers[4].text = unitPrice.toStringAsFixed(2);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    //loadAd();
    //loadAdInterstitalad();
    initializeControllersList();
  }

  void initializeControllersList() {
    controllersList = List.generate(
      itemCount,
      (index) {
        TextEditingController itemNameController = TextEditingController();
        itemNameController.text = "แบบที่ ${index + 1}";
        return [
          itemNameController,
          TextEditingController(), // สร้าง controller สำหรับ price
          TextEditingController(), // สร้าง controller สำหรับ quantity
          TextEditingController(), // สร้าง controller สำหรับ volume
          TextEditingController(), // สร้าง controller สำหรับ unitPrice
        ];
      },
    );
  }

  void newControllersList(value) {
    controllersList = List.generate(
      value,
      (index) {
        TextEditingController itemNameController = TextEditingController();
        itemNameController.text = "แบบที่ ${index + 1}";
        return [
          itemNameController,
          TextEditingController(), // สร้าง controller สำหรับ price
          TextEditingController(), // สร้าง controller สำหรับ quantity
          TextEditingController(), // สร้าง controller สำหรับ volume
          TextEditingController(), // สร้าง controller สำหรับ unitPrice
        ];
      },
    );
  }

  void addItemToList() {
    setState(() {
      if (isPriceAndQuantityFilledLast()) {
        listcheapsort.clear();
        resetCompare();
      }
      if (!isPriceAndQuantityFilledLast()) {
        listcheapsort.clear();
        resetCompare();
      }

      itemCount++;
      TextEditingController itemNameController = TextEditingController();
      itemNameController.text = "แบบที่ ${itemCount}";
      List<TextEditingController> controllers = [
        itemNameController,
        TextEditingController(), // สร้าง controller สำหรับ price
        TextEditingController(), // สร้าง controller สำหรับ quantity
        TextEditingController(), // สร้าง controller สำหรับ volume
        TextEditingController(), // สร้าง controller สำหรับ unitPrice
      ];
      controllersList.add(controllers);
    });
    if (controllersList.length > 2) {
      setState(() {
        visblefromcompare = false;
        visbleTextrage = true;
      });
    } else {
      setState(() {
        visbleTextrage = false;
        visblefromcompare = true;
      });
    }
  }

  void deleteItemToList() {
    if (itemCount == 3) {
      //showInterstitialAd();
      setState(() {
        if (!isPriceAndQuantityFilled()) {
          resetCompare();
        } else {
          calculateCompareAll();
          calculateUnitPrice();
        }

        visbleTextrage = false;
        visblefromcompare = true;
      });
    }
    if (itemCount > 2) {
      controllersList[itemCount - 1].forEach((controller) {
        controller.dispose(); // ลบ TextEditingController
      });
      try {
        controllersList.removeAt(itemCount - 1);
      } catch (FormatException) {}

      setState(() {
        itemCount--;
        try {
          listcheapsort.removeAt(itemCount - 1);
        } catch (FormatException) {}
        if (isPriceAndQuantityFilled()) {
          calculateCompareAll();
          calculateUnitPrice();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: _bannerAd != null
              ? EdgeInsets.fromLTRB(10, 50, 10, 60)
              : EdgeInsets.fromLTRB(10, 50, 10, 120),
          child: Column(
            children: [
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: List.generate(itemCount, (index) {
                  final itemIndex = index + 1;
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (_) {
                            if (isPriceAndQuantityFilled()) {
                              calculateUnitPrice();
                              calculateCompareAll();
                            }
                          },
                          controller: controllersList[itemIndex - 1][0],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: "แบบที่ " + itemIndex.toString(),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2.0,
                              ), // เส้นกรอบด้านล่าง
                            ),
                          ),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),

                            onChanged: (_) {
                              if (isPriceAndQuantityFilled()) {
                                calculateUnitPrice();
                                calculateCompareAll();
                              }
                            },
                            controller: controllersList[itemIndex - 1]
                                [1], // priceController
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: "0.00"),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2.0,
                              ), // เส้นกรอบด้านล่าง
                            ),
                          ),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),

                            onChanged: (_) {
                              if (isPriceAndQuantityFilled()) {
                                calculateUnitPrice();
                                calculateCompareAll();
                              }
                            },
                            controller: controllersList[itemIndex - 1]
                                [2], // quantityController
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(hintText: "0.00"),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 2.0,
                              ), // เส้นกรอบด้านล่าง
                            ),
                          ),
                          child: TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),

                            onChanged: (_) {
                              // เรียกใช้ฟังก์ชันเพื่อตรวจสอบสถานะของข้อมูล
                              if (isPriceAndQuantityFilled()) {
                                calculateUnitPrice();
                                calculateCompareAll();
                              }
                            },
                            controller: controllersList[itemIndex - 1]
                                [3], // volumeController
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "0.00",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: TextField(
                          controller: controllersList[itemIndex - 1]
                              [4], // unitPriceController
                          textAlign: TextAlign.center,
                          canRequestFocus: false,
                          readOnly: true,
                          decoration: InputDecoration(hintText: "0.00"),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: Text(
                  textAlign: TextAlign.center,
                  "เมื่อกรอกราคาและปริมาตรครบทุกรายการขึ้นไประบบจะคำนวณให้อัตโนมัติ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    color: Color.fromARGB(255, 179, 255, 182),
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ผลการเปรียบเทียบ",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ValueListenableBuilder(
                            valueListenable: compareText,
                            builder: (context, value, child) {
                              return Text(value,
                                  style: TextStyle(fontSize: 18));
                            },
                          ),
                          Visibility(
                            visible: visblefromcompare,
                            child: Column(children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ถูกกว่าหน่วยละ",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(
                                    width: double.minPositive,
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: compareCheaperPriceText,
                                    builder: (context, value, child) {
                                      return Text(value + " บาท",
                                          style: TextStyle(fontSize: 18));
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "หรือถูกกว่า",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  ValueListenableBuilder(
                                    valueListenable: comparePercentageText,
                                    builder: (context, value, child) {
                                      return Text(value + " %",
                                          style: TextStyle(fontSize: 18));
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ValueListenableBuilder(
                                      valueListenable: unitsaveText,
                                      builder: (context, value, child) {
                                        return Text(
                                          overflow: TextOverflow.ellipsis,
                                          "ถ้าซื้อ " +
                                              value +
                                              " อัน" +
                                              " จะประหยัดได้",
                                          style: TextStyle(
                                            fontSize: 18,
                                          ),
                                        );
                                      }),
                                  ValueListenableBuilder(
                                      valueListenable: saveMoneyText,
                                      builder: (context, value, child) {
                                        return Text(
                                          value + " บาท",
                                          style: TextStyle(fontSize: 18),
                                        );
                                      })
                                ],
                              )
                            ]),
                          ),
                          Visibility(
                            visible: visbleTextrage,
                            child: Text(
                              "เรียงลำดับจากถูกที่สุด",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Visibility(
                              visible: visbleTextrage,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: listcheapsort.length,
                                itemBuilder: (context, index) {
                                  int item = index + 1;
                                  String itemNameHint = listcheapsort[index];
                                  return Text(
                                    item.toString() + "." + itemNameHint,
                                    style: TextStyle(fontSize: 18),
                                  );
                                },
                              ))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 0), // changes position of shadow
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ชื่อสินค้า",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(
                  width: 5,
                ),
                Text("ราคา",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(
                  width: 5,
                ),
                Text("ปริมาตร",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(
                  width: 5,
                ),
                Text("จำนวน",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(
                  width: 5,
                ),
                Text("หน่วยละ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_bannerAd != null)
                  Flexible(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Container(
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 231, 231, 231),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => setState(() {
                                      _clearAllEdittext();
                                      //showInterstitialAd();
                                    }),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "รีเซ็ต",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 255, 60, 60),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        deleteItemToList();
                                      });
                                    },
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "ลบสินค้า",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  color: AppColors.mainColor,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        addItemToList();
                                      });
                                    },
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "เพิ่มสินค้า",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ))
      ],
    );
  }
}

showAlertDialog(BuildContext context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //String appName = packageInfo.appName;
  //String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('เกี่ยวกับ'),
        content: Text(
          'เวอร์ชั่น' + version + " " + "($buildNumber)" + " Khathawut",
          style: TextStyle(fontSize: 18),
        ),
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
                overlayColor: MaterialStatePropertyAll(
                    Color.fromARGB(178, 177, 255, 180))),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'ปิด',
              style: TextStyle(color: AppColors.mainColor),
            ),
          ),
        ],
      );
    },
  );
}
