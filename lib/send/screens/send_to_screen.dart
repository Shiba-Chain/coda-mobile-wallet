import 'package:coda_wallet/global/global.dart';
import 'package:coda_wallet/route/routes.dart';
import 'package:coda_wallet/types/send_data.dart';
import 'package:coda_wallet/util/navigations.dart';
import 'package:coda_wallet/widget/app_bar/app_bar.dart';
import 'package:coda_wallet/widget/ui/custom_box_shadow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

_gotoSendAmount(BuildContext context, SendData sendData) {
  Navigator.of(context).pushReplacementNamed(SendAmountRoute, arguments: sendData);
}

class SendToScreen extends StatefulWidget {
  SendToScreen({Key key}) : super(key: key);

  @override
  _SendToScreenState createState() => _SendToScreenState();
}

class _SendToScreenState extends State<SendToScreen> {
  TextEditingController _toController   = TextEditingController();
  TextEditingController _memoController = TextEditingController();
  dynamic _qrResult;
  final _focusNodeTo       = FocusNode();
  final _focusNodeMemo     = FocusNode();
  bool _validInput = true;
  SendData _sendData;

  _fillQrAddress() async {
    _qrResult = await toQrScanScreen(context);
    _toController.text = '$_qrResult';
    _sendData.to = _toController.text;
    if(null != _toController.text && _toController.text.isNotEmpty) {
      _validInput = true;
    } else {
      _validInput = false;
    }
    setState(() {});
  }

  bool _checkInputValidation() {
    if(_sendData.to == null || _sendData.to.isEmpty) {
      setState(() {
        _validInput = false;
      });
    } else {
      _gotoSendAmount(context, _sendData);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _memoController?.dispose();
    _toController?.dispose();
    _focusNodeMemo?.dispose();
    _focusNodeTo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(375, 812), allowFontScaling: false);
    _sendData = ModalRoute.of(context).settings.arguments;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: buildNoTitleAppBar(context),
      body: KeyboardActions(
        tapOutsideToDismiss: true,
        autoScroll: true,
        config: KeyboardActionsConfig(
          keyboardSeparatorColor: Colors.grey,
          nextFocus: false,
          actions: [ KeyboardActionsItem(focusNode: _focusNodeTo), KeyboardActionsItem(focusNode: _focusNodeMemo)]
        ),
        child:
          Container(
            child: SingleChildScrollView(child: _buildSendToBody(context)),
            decoration: BoxDecoration(
              image: DecorationImage(
                alignment: Alignment.bottomCenter,
                image: AssetImage('images/common_bg.png',),
                fit: BoxFit.fitWidth
              ),
            ),
          )
        )
    );
  }

  _buildSendToBody(BuildContext context) {
    return IntrinsicHeight(child:
      Column(children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 30.w, right: 30.w),
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 37.h),
                Text('Where are you sending MINA to?', textAlign: TextAlign.left, style: TextStyle(fontSize: 28.sp, color: Colors.black)),
                Container(height: 29.h),
                Text('SEND TO', textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Color(0xff2d2d2d))),
                Container(height: 4.h),
                _buildToAddressField(context),
                _buildInvalidateTip(),
                Text('MEMO', textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Color(0xff2d2d2d))),
                Container(height: 4.h),
                _buildMemoField(),
              ],
            )
          ),
          flex: 12,
        ),
        Expanded(
          flex: 1,
          child: InkWell(
            onTap: _checkInputValidation,
            child: Container(
              padding: EdgeInsets.only(top: 14.h, bottom: 14.h, left: 94.w, right: 94.w),
              decoration: getMinaButtonDecoration(topColor: Color(0xff9fe4c9)),
              child: Text('CONTINUE',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Color(0xff2d2d2d))),
            ),
          )
        )
      ]
    )
    );
  }

  _buildInvalidateTip() {
    return Container(
      margin: EdgeInsets.only(top: 6.h, bottom: 6.h, right: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text('You must enter an address',
            textAlign: TextAlign.right, style: TextStyle(fontSize: 16.sp, color: _validInput ? Colors.transparent : Colors.red)),
        ],
      )
    );
  }

  _buildToAddressField(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 13.h, bottom: 13.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(2.w)),
        border: Border.all(color: Color(0xff757575), width: 1.w)
      ),
      child: Row(children: [
        Expanded(
          flex: 1,
          child: TextField(
            enableInteractiveSelection: true,
            focusNode: _focusNodeTo,
            controller: _toController,
            onChanged: (text) {
              if(null != text && text.isNotEmpty) {
                _validInput = true;
              } else {
                _validInput = false;
              }
              _sendData.to = text;
              setState(() {

              });
            },
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autofocus: false,
            decoration: InputDecoration.collapsed(
              hintText: 'Tap to Paste Address',
              hintStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal, color: Color(0xffbdbdbd)))
          )),
          Container(width: 12.w),
          InkWell(
            child: Image.asset('images/qr_scanner.png', width: 28.w, height: 28.w),
            onTap: _fillQrAddress,
          )
        ],
      ),
    );
  }

  _buildMemoField() {
    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 13.h, bottom: 13.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(2.w)),
        border: Border.all(color: Color(0xff757575), width: 1.w)
      ),
      child: TextField(
        enableInteractiveSelection: true,
        focusNode: _focusNodeMemo,
        controller: _memoController,
        onChanged: (text) {
          _sendData.memo = text;
        },
        maxLines: null,
        keyboardType: TextInputType.multiline,
        autofocus: false,
        decoration: InputDecoration.collapsed(
          hintText: 'Personal Note(optional)',
          hintStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.normal, color: Color(0xffbdbdbd)))
        )
    );
  }
}
