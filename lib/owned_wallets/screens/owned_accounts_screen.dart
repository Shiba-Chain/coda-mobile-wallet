import 'package:coda_wallet/constant/constants.dart';
import 'package:coda_wallet/global/global.dart';
import 'package:coda_wallet/owned_wallets/blocs/owned_accounts_entity.dart';
import 'package:coda_wallet/owned_wallets/screens/owned_accounts_dialog.dart';
import 'package:coda_wallet/util/navigations.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../blocs/owned_accounts_bloc.dart';
import '../blocs/owned_accounts_events.dart';
import '../blocs/owned_accounts_states.dart';
import '../../util/format_utils.dart';
import '../query/owned_accounts_query.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

class OwnedAccountsScreen extends StatefulWidget {
  OwnedAccountsScreen({Key key}) : super(key: key);

  @override
  _OwnedAccountsScreenState
    createState() => _OwnedAccountsScreenState();
}

class _OwnedAccountsScreenState extends State<OwnedAccountsScreen> with WidgetsBindingObserver, RouteAware {
  OwnedAccountsBloc _ownedAccountsBloc;

  Future requestPermission() async {
    Map<PermissionGroup, PermissionStatus> permissions =
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);

    PermissionStatus permission =
      await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);

    if (permission == PermissionStatus.granted) {
      print('storage permission granted');
    } else {
      print('storage permission denied');
    }
  }

  @override
  void initState() {
    super.initState();
    FLog.info(
        className: 'OwnedAccountsScreen',
        methodName: 'initState',
        text: '');
    WidgetsBinding.instance.addObserver(this);
    _ownedAccountsBloc = BlocProvider.of<OwnedAccountsBloc>(context);
    requestPermission();
  }

  @override
  void dispose() {
    FLog.info(
        className: 'OwnedAccountsScreen',
        methodName: 'dispose',
        text: '');
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _ownedAccountsBloc = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeDependencies();
    //print('OwnedAccountsScreen didChangeAppLifecycleState()');
    FLog.info(
      className: "OwnedAccountsScreen",
      methodName: "didChangeAppLifecycleState",
      text: "${state.index}");
    if (state == AppLifecycleState.resumed) {
      if(!_ownedAccountsBloc.isAccountLoading) {
        _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void didPopNext() {
    super.didPopNext();
    print('OwnedAccountsScreen: didPopNext()');
    if(!_ownedAccountsBloc.isAccountLoading) {
      _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY));
    }
  }

  @override
  void didPush() {
    super.didPush();
    print('OwnedAccountsScreen: didPush(), isLoading=${_ownedAccountsBloc.isAccountLoading}');
    if(!_ownedAccountsBloc.isAccountLoading) {
      _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY));
    }
  }

  @override
  void didPushNext() {
    final route = ModalRoute.of(context).settings.name;
    print('OwnedAccountsScreen didPushNext() route: $route');
  }

  @override
  void didPop() {
    final route = ModalRoute.of(context).settings.name;
    print('OwnedAccountsScreen didPop() route: $route');
  }

  _changeRpcServerAddress() async {
    bool needRefresh = await toSettingScreen(context);
    if(needRefresh) {
      _ownedAccountsBloc.newCodaService();
      _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY));
    }
  }

  Future<Null> _onRefresh() async {
    if(!_ownedAccountsBloc.isAccountLoading) {
      _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY));
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(1080, 2316), allowFontScaling: false);
    return Scaffold(
      backgroundColor: primaryBackgroundColor,
      appBar: _buildAccountsAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BlocBuilder<OwnedAccountsBloc, OwnedAccountsStates>(
          builder: (BuildContext context, OwnedAccountsStates state) {
            return _buildAccountsBody(context, state);
          }
        )
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  Widget _buildAccountsAppBar() {
    return PreferredSize(
      child: AppBar(
        title: Text('Accounts',
          style: TextStyle(fontSize: APPBAR_TITLE_FONT_SIZE.sp, color: Color(0xff0b0f12))),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Image.asset('images/setting.png', width: 100.w, height: 100.w),
            tooltip: 'Setting',
            iconSize: 24,
            onPressed: _changeRpcServerAddress,
          )
        ]
      ),
      preferredSize: Size.fromHeight(APPBAR_HEIGHT.h)
    );
  }

  Widget _buildActionButton() {
    return SpeedDial(
      child: Icon(Icons.add),
      children:[
        SpeedDialChild(
          child: Icon(Icons.create),
          backgroundColor: Colors.red,
          label: 'Create',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => showCreateAccountDialog(context)
        ),
        SpeedDialChild(
          label: 'Get Log',
          child: Icon(Icons.delete),
          backgroundColor: Colors.orange,
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: _storeLogs,
        ),
      ]
    );
  }

  _storeLogs() {
    //local storage
    final LogsStorage _storage = LogsStorage.instance;
    StringBuffer buffer = StringBuffer();
    // get all logs and write to file
    FLog.getAllLogs().then((logs) {
      logs.forEach((log) {
        buffer.write(Formatter.format(log, flogConfig));
      });

      _storage.writeLogsToFile(buffer.toString());
//      print(buffer.toString());
      buffer.clear();
    });
  }

  Widget _buildAccountsBody(BuildContext context, OwnedAccountsStates state) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(height: 8, color: Color(0xffeeeeee)),
        Container(height: 6,),
        Expanded(
          flex: 1,
          child: Padding(
          padding: EdgeInsets.only(left: globalHPadding.w, right: globalHPadding.w),
          child: _buildAccountsWidget(context, state))
        )
      ],
    );
  }

  Widget _buildAccountsWidget(
    BuildContext context, OwnedAccountsStates state) {

    if(state is FetchOwnedAccountsLoading) {
      List<Account> data = state.data as List;
      if(null == data || 0 == data.length) {
        return Center(
            child: CircularProgressIndicator()
        );
      }
      return _buildAccountListWidget(data);
    }

    if(state is FetchOwnedAccountsFail) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error),
            RaisedButton(
              padding: EdgeInsets.only(top: 4.h, bottom: 4.h, left: 80, right: 80),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6.0))),
              onPressed: () => _ownedAccountsBloc.add(FetchOwnedAccounts(OWNED_ACCOUNTS_QUERY)),
              color: Colors.blueAccent,
              child: Text('Refresh', style: TextStyle(color: Colors.white),)
            )
          ]
        )
      );
    }

    if(state is FetchOwnedAccountsSuccess) {
      List<Account> data = state.data as List;
      return _buildAccountListWidget(data);
    }

    if(state is ToggleLockStatusFail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final snackBar = SnackBar(content: Text('Lock Account Failed: ${state.error}'));
        Scaffold.of(context).showSnackBar(snackBar);
      });
      return Container();
    }

    if(state is ToggleLockStatusSuccess) {
      List<Account> data = state.data as List;
      return _buildAccountListWidget(data);
    }

    if(state is CreateAccountSuccess) {
      List<Account> data = state.data as List;
      return _buildAccountListWidget(data);
    }

    return Container();
  }
  
  _accountsTapCallback(BuildContext context, Account account) {
    toAccountTxnsScreen(context, account);
  }

  Widget _buildAccountName(Account account) {
    String name = globalPreferences.getString(account.publicKey);
    if(null == name || name.isEmpty) {
      name = 'Default Name';
    }
    return Text(name, style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.left,);
  }

  _buildAccountContent(BuildContext context, Account account) {
    String publicKey = account.publicKey;
    String formattedTokenNumber = formatTokenNumber(account.balance);

    return Column(
      children: [
        _buildAccountName(account),
        Container(height: 6),
        _publicKeyText(publicKey),
        Container(height: 10),
        Container(height: 0.5, color: Color(0xffdddddd)),
        Container(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(flex: 1, child: Text("Balance: $formattedTokenNumber")),
            Container(width: 10),
            GestureDetector(
              child: _lockStatusImage(account.locked),
              onTap: () { _clickLock(context, account); }
            ),
            Container(width: 10),
            // GestureDetector(
            //   child: Image.asset('images/delete.png', width: 16, height: 16),
            //   onTap: () { _clickLock(context, account); }
            // )
          ]
        )
      ],
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max
    );
  }

  Widget _buildAccountItem(
    BuildContext context, Account itemData) {

    return GestureDetector(
      onTap: () { _accountsTapCallback(context, itemData); },
      child: Card(
        elevation: 4.0,
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.only(left: 14.0, right: 14.0, top: 12, bottom: 8),
          child: _buildAccountContent(context, itemData)
        )
      )
    );
  }

  _publicKeyText(String publicKey) {
    return Text(publicKey, softWrap: true,
      textAlign: TextAlign.left, overflow: TextOverflow.ellipsis, maxLines: 1);
  }

  _lockStatusImage(bool locked) {
    return Image.asset(locked ?
      'images/locked_black.png' : 'images/unlocked_green.png', width: 16, height: 16);
  }

  _clickLock(BuildContext context, Account account) {
    if(null == account) {
      return;
    }

    if(account.locked) {
      showUnlockAccountDialog(context, account);
      return;
    }

    if(!account.locked) {
      showLockAccountDialog(context, account);
    }
  }

  Widget _buildAccountListWidget(List<Account> accountList) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: accountList.length,
      itemBuilder: (context, index) {
        return _buildAccountItem(context, accountList[index]);
      },
      separatorBuilder: (context, index) { return Container(); }
    );
  }
}

