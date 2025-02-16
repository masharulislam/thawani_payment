import 'package:flutter/material.dart';
import 'package:thawani_payment/widgets/pay.dart';
import '../class/create.dart';
import '../class/status.dart';
import '../helper/req_helper.dart';

class ThawaniPayBtn extends StatefulWidget {
  const ThawaniPayBtn(
      {Key? key,
      required this.api,
      required this.products,
      required this.onCreate,
      required this.onCancelled,
      required this.onPaid,
      this.child,
      required this.pKey,
      this.metadata,
      required this.clintID,
      this.buttonStyle,
      this.testMode,
      this.onError,
      this.successUrl,
      this.cancelUrl})
      : super(key: key);

  ///  API Code From Thawani Company
  ///
  ///  For Test Mode: rRQ26GcsZzoEhbrP2HZvLYDbn9C9et
  final String api;

  /// The Widget  Shown In The Button , By Default it have Text
  ///
  /// Text("Pay",style: TextStyle(color: Colors.white,fontSize: 17),)
  final Widget? child;

  /// Button Style
  ///
  /// ButtonStyle(
  ///     elevation: MaterialStateProperty.all(0),
  ///     shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  ///    backgroundColor: MaterialStateProperty.all(const Color(0xff4FB76C)),
  ///   )
  final ButtonStyle? buttonStyle;

  /// The Publishable Key From Thawani Company
  ///
  /// For Test Mode: HGvTMLDssJghr9tlN9gr4DVYt0qyBy
  final String pKey;

  /// The Clint Id to be generated by merchant to identify the session (From Thawani API Doc).
  ///
  /// You can use The User ID As Clint ID
  final String clintID;

  /// The customer would be redirected to successUrl if payment processed successfully (From Thawani API Doc).
  ///
  /// In This Package , The URL Unuseful
  final String? successUrl;

  /// The customer would be redirected to successUrl if he decides to cancel the payment (From Thawani API Doc).
  ///
  /// In This Package , The URL Unuseful
  final String? cancelUrl;

  /// A list of products the customer is purchasing. maximum  100 products (From Thawani API Doc).
  ///
  /// [
  ///      {
  ///        "name": "product Name",
  ///         "unit_amount": the price by Baisa, >=100 <=5000000000
  ///        "quantity": the quantity of the line product,  >=1 <=100
  ///       }
  ///     ]
  final List<Map> products;

  /// Useful for storing additional information about your products, customers (From Thawani API Doc).
  ///
  /// storing Any Data about your products, customers(users)
  ///
  /// EX:
  /// { "userName":"Nasr Al-Rahbi", "Twitter":"abom_me"}
  final Map<String, dynamic>? metadata;

  /// Make It true If You Want Test The Package Or The Api
  ///
  /// By Default It's false
  ///
  /// testMode: false
  final bool? testMode;

  ///The Function And The Result Of Data After Create Session.
  final void Function(Create create) onCreate;

  ///The Function And The Result Of Data If The User  Cancelled The Payment.
  final void Function(StatusClass payStatus) onCancelled;

  ///The Function And The Result Of Data If The User  Cancelled The Payment.
  final void Function(StatusClass payStatus) onPaid;

  ///The Function And The Reason Of The Error,  If Any Error Happen.
  final Function(Map error)? onError;

  @override
  State<ThawaniPayBtn> createState() => _ThawaniPayBtnState();
}

class _ThawaniPayBtnState extends State<ThawaniPayBtn> {
  late ButtonStyle buttonStyle = widget.buttonStyle ??
      ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        backgroundColor: MaterialStateProperty.all(const Color(0xff4FB76C)),
      );
  late Widget child = widget.child ??
      const Text(
        "Pay",
        style: TextStyle(color: Colors.white, fontSize: 17),
      );
  late String api = widget.api;
  late bool testMode = widget.testMode ?? false;
  late String clintID = widget.clintID;
  late String key = widget.pKey;
  late List<Map> products = widget.products;
  late Map<String, dynamic> dataBack;

  Future<Create> createS() async {
    return Create.fromJson(dataBack);
  }

  Future<StatusClass> payStatus(dataStatute) async {
    return StatusClass.fromJson(dataStatute);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: buttonStyle,
        onPressed: () async {
          dataBack = await RequestHelper.postRequest(
              api,
              {
                "client_reference_id": clintID,
                "mode": "payment",
                "products": products,
                "success_url": widget.successUrl ??
                    'https://abom.me/package/thawani/suc.php',
                "cancel_url": widget.cancelUrl ??
                    "https://abom.me/package/thawani/can.php",
                widget.metadata != null ? "metadata" : widget.metadata: null,
              },
              testMode);
          if (dataBack['code'] == 2004) {
            createS().then((value) => {widget.onCreate(value)});

            if (!mounted) return;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PayWidget(
                          api: widget.api,
                          uri: dataBack['data']['session_id'],
                          url: testMode == true
                              ? 'https://uatcheckout.thawani.om/pay/${dataBack['data']['session_id']}?key=${widget.pKey}'
                              : 'https://checkout.thawani.om/pay/${dataBack['data']['session_id']}?key=${widget.pKey}',
                          paid: (statusClass) {
                            payStatus(statusClass)
                                .then((value) => {widget.onPaid(value)});
                          },
                          unpaid: (statusClass) {
                            payStatus(statusClass)
                                .then((value) => {widget.onCancelled(value)});
                          },
                          testMode: testMode,
                        )));
          } else if (dataBack['code'] != 2004) {
            return widget.onError!(dataBack);
          } else if (dataBack['code'] == null) {
            return widget.onError!(dataBack);
          }
        },
        child: child);
  }
}
