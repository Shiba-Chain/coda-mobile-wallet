import 'package:coda_wallet/constant/constants.dart';
import 'package:coda_wallet/global/global.dart';
import 'package:coda_wallet/route/routes.dart';
import 'package:coda_wallet/stake/blocs/stake_bloc.dart';
import 'package:coda_wallet/stake/blocs/stake_events.dart';
import 'package:coda_wallet/stake/blocs/stake_states.dart';
import 'package:coda_wallet/stake/query/get_consensus_state.dart';
import 'package:coda_wallet/util/stake_utils.dart';
import 'package:coda_wallet/widget/account/account_list.dart';
import 'package:coda_wallet/widget/dialog/loading_dialog.dart';
import 'package:coda_wallet/widget/ui/countdown_timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_countdown_timer/countdown.dart';
import 'package:flutter_countdown_timer/countdown_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const SECONDS_PER_EPOCH = SLOT_PER_EPOCH * 3 * 60;

class StakeScreen extends StatefulWidget {
  StakeScreen({Key? key}) : super(key: key);

  @override
  _StakeScreenState createState() => _StakeScreenState();
}

class _StakeScreenState extends State<StakeScreen> with AutomaticKeepAliveClientMixin {
  bool _stakeEnabled = true;
  late var _stakeBloc;
  late CountdownController _countdownController;
  int? _currentEpoch;

  // Callback when counting down to new epoch
  void _onCountdownEnd() {
    _countdownController.value = Duration(seconds: SECONDS_PER_EPOCH).inMilliseconds;
    _countdownController.start();
  }

  @override
  void initState() {
    super.initState();
    print('StakeScreen initState()');
    _stakeBloc = BlocProvider.of<StakeBloc>(context);
    _stakeBloc.add(GetConsensusState(CONSENSUS_STATE_QUERY));

    _countdownController =
      CountdownController(duration: Duration(), onEnd: _onCountdownEnd);
  }

  @override
  void dispose() {
    print('StakeScreen dispose()');
    _stakeBloc = null;
    if(_countdownController.isRunning) {
      _countdownController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('StakeScreen build()');
    ScreenUtil.init(
      BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height,
      ),
      designSize: Size(375, 812),
      orientation: Orientation.portrait
    );
    return _buildWalletHomeBody();
  }

  Widget _buildWalletHomeBody() {
    if(_stakeEnabled) {
      return _buildStakedHome();
    }

    return _buildNoStakeHome();
  }

  _buildStakedHome() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(children: [
          Container(height: 42.h),
          Container(
            width: double.infinity,
            child: Center(
              child: Image.asset('images/stake_logo_deep_color.png', width: 80.w, height: 80.w,),
            )
          ),
          Container(height: 10.h),
          walletStaking() ?
            Text('You Are Staking', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.normal, color: Colors.black)) :
            Text('You Are Not Staking', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.normal, color: Colors.black)),
          Container(height: 20.h),
          Padding(
            padding: EdgeInsets.only(left: 13.w, right: 13.w),
            child: BlocBuilder<StakeBloc, StakeStates>(
              builder: (BuildContext context, StakeStates state) {
                int epoch = 0;
                int slot = 0;
                if(state is GetConsensusStateFailed) {
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    ProgressDialog.dismiss(context);
                    String error = state.data;
                    Scaffold.of(context).showSnackBar(SnackBar(content: Text(error)));
                  });
                }

                if(state is GetConsensusStateLoading) {
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    ProgressDialog.showProgress(context);
                  });
                }

                if(state is GetConsensusStateSuccess) {
                  WidgetsBinding.instance!.addPostFrameCallback((_) {
                    ProgressDialog.dismiss(context);
                  });
                  epoch = state.epoch ?? 0;
                  _currentEpoch = epoch;
                  slot = state.slot ?? 0;
                  int secondsInSlot = (SLOT_PER_EPOCH - slot) * 3 * 60;
                  // Also, get delta time from local timestamp
                  DateTime now = DateTime.now();
                  int seconds = now.second;
                  int minutes = now.minute;
                  int deltaMinute = minutes % 3;
                  int deltaSeconds = deltaMinute * 60 + seconds;
                  _countdownController.value = Duration(seconds: secondsInSlot + deltaSeconds).inMilliseconds;
                  _countdownController.start();
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text('Epoch: $epoch', textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Time Remain: ', textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),),
                        Container(width: 4.w,),
                        Countdown(
                          countdownController: _countdownController,
                          builder: (_, Duration time) {
                            return getTimerWidget(time);
                          }
                        ),
                      ],
                    )
                  ],
                );
              }
            )
          ),
          Container(height: 14.h),
          Expanded(
            child: buildAccountList((index) {
              // Check if this account has been staked.
              if(null == _currentEpoch) {
                return;
              }
              String? accountAddress = globalHDAccounts.accounts![index]!.address;
              String? stakeAddress = globalHDAccounts.accounts![index]!.stakingAddress;
              Map<String, dynamic> params = Map<String, dynamic>();
              params['accountIndex'] = index;
              params['epoch'] = _currentEpoch;
              if(null == stakeAddress || stakeAddress.isEmpty || (accountAddress == stakeAddress)) {
                Navigator.of(context).pushNamed(AccountNoStakeRoute, arguments: params);
              } else {
                Navigator.of(context).pushNamed(AccountStakeRoute, arguments: params);
              }
            })
          )
        ]),
      ],
    );
  }

  _buildNoStakeHome() {
    return Container();
  }

  @override
  bool get wantKeepAlive => false;
}