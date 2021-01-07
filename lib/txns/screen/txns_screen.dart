import 'package:coda_wallet/account_txns/blocs/account_txns_events.dart';
import 'package:coda_wallet/txns/blocs/txns_bloc.dart';
import 'package:coda_wallet/txns/blocs/txns_events.dart';
import 'package:coda_wallet/txns/blocs/txns_states.dart';
import 'package:coda_wallet/txns/query/account_txns_query.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TxnsScreen extends StatefulWidget {
  TxnsScreen({Key key}) : super(key: key);

  @override
  _TxnsScreenState createState() => _TxnsScreenState();
}

class _TxnsScreenState extends State<TxnsScreen> {
  TxnsBloc _txnsBloc;

  _refreshTxns() {
    Map<String, dynamic> variables = Map<String, dynamic>();
    variables['publicKey'] = 'B62qrPN5Y5yq8kGE3FbVKbGTdTAJNdtNtB5sNVpxyRwWGcDEhpMzc8g';
    variables['before'] = null;
    _txnsBloc.add(RefreshTxns(TXNS_QUERY, variables: variables));
  }

  @override
  void initState() {
    super.initState();
    _txnsBloc = BlocProvider.of<TxnsBloc>(context);
    _refreshTxns();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(375, 812), allowFontScaling: false);
    return BlocBuilder<TxnsBloc, TxnsStates>(
      builder: (BuildContext context, TxnsStates state) {
        return Column(
          children: [
            _buildTxnHeader(),
            Container(height: 2.h,),
            Container(height: 0.5.h, color: Color.fromARGB(74, 60, 60, 67)),
            Expanded(
              flex: 1,
              child: _buildTxnList(context, state)
            )
          ]
        );
      }
    );
  }

  _buildTxnHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text('Account#0', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, color: Color(0xff212121)))
          ),
          Positioned(
            right: 20.w,
            child: Text('All', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: Color(0xff212121)))
          )
        ],
      ),
    );
  }

  _buildTxnList(BuildContext context, TxnsStates state) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 10,
      itemBuilder: (context, index) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: _buildTxnItem(),
          onTap: null
        );
      },
      separatorBuilder: (context, index) {
        return Container(
          height: 1.h,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container()
              ),
              Expanded(
                flex: 6,
                child: Container(color: Color(0xffc1c1c1))
              )
            ],
          ),
        );
      },
//      controller: _scrollController
    );
  }

  _buildTxnItem() {
    return Container(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 15.h, bottom: 15.h),
      child: Row(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: <TextSpan>[
            TextSpan(
              text: 'DEC\n',
              style: TextStyle(fontSize: 11.sp, color: Colors.black)),
            TextSpan(
              text: '31',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 20.sp
              )),
          ])),
          Container(width: 20.w,),
          Image.asset('images/txsend.png', height: 40.w, width: 40.w),
          Container(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sent', textAlign: TextAlign.left, style: TextStyle(fontSize: 14.sp)),
              Text('Pending', textAlign: TextAlign.left, style: TextStyle(fontSize: 14.sp, color: Color(0xffbebebe))),
            ],
          ),
          Container(width: 20.w),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text('+1232.45', textAlign: TextAlign.right, style: TextStyle(fontSize: 17.sp)),
                Text('\$65.34', textAlign: TextAlign.right, style: TextStyle(fontSize: 12.sp, color: Color(0xff979797)))
              ]
            ),
          )
        ],
      ),
    );
  }
}