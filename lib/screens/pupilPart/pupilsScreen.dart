import 'package:flutter/material.dart';

import 'package:badges/badges.dart';
import 'package:iris_tools/widgets/optionsRow/checkRow.dart';
import 'package:iris_tools/widgets/searchBar.dart';
import 'package:iris_tools/modules/stateManagers/refresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/stateBase.dart';
import '/screens/pupilPart/ListBuilderPupils.dart';
import '/screens/pupilPart/pupilsCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/queryFiltering.dart';
import '/system/session.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/views/preWidgets.dart';

class UserListScreen extends StatefulWidget {
  UserListScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return UserListScreenState();
  }
}
///=========================================================================================================
class UserListScreenState extends StateBase<UserListScreen> {
  StateXController stateController = StateXController();
  UserListCtr controller = UserListCtr();
  RefreshController appBarRefresher = RefreshController();

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getBody();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  getBody() {
    return SizedBox(
      width: AppSizes.getScreenWidth(context),
      height: AppSizes.getScreenHeight(context),

      child: StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          if(!Session.hasAnyLogin()) {
            return mustLogin();
          }

          switch(ctr.mainState){
            case StateXController.state$loading:
              return PreWidgets.flutterLoadingWidget$Center();
          }

          return showStudentList();
        },
      ),
    );
  }
  ///==========================================================================================================
  Widget mustLogin(){
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
        child: Text('${tC('mustLoginFirstByAccount')}').subAlpha(),
      ),
    );
  }

  Widget noStudents(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PreWidgets.notFound(),
          SizedBox(height: 40,),
          Text('${tInMap('pupilPage', 'youHaveNoStudents')}').subAlpha(),
        ],
      ),
    );
  }

  Widget showStudentList(){
    return Column(
      children: [
        getFilterBar(),

        Expanded(
          child: getListView(),
        ),
      ],
    );
  }

  Widget getFilterBar(){
    return Refresh(
        controller: appBarRefresher,
        builder: (context, ctr) {
          return ColoredBox(
            color: AppThemes.currentTheme.appBarBackColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: SearchBar(
                    iconColor: AppThemes.checkPrimaryByWB(AppThemes.currentTheme.primaryColor, AppThemes.currentTheme.textColor),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    hint: tInMap('optionsKeys', controller.filterRequest.getSearchSelectedForce().key)?? '',
                    shareTextController: (c){
                      controller.searchEditController = c;
                    },
                    searchEvent: (text){
                      if(controller.filterRequest.setTextToSelectedSearch(text)) {
                        controller.resetRequest();
                      }
                    },
                    onClearEvent: (){
                      if(controller.filterRequest.setTextToSelectedSearch(null)) {
                        controller.resetRequest();
                      }
                    },
                  ),
                ),

                Row(
                  children: [
                    IconButton(
                        icon: Icon(IconList.searchOpM).whiteOrDifferentOnPrimary(),
                        onPressed: () async {
                          (await controller.onSearchOptionClick.delay()).call();
                        }
                    ),

                    IconButton(
                        icon: Badge(
                            padding: EdgeInsets.all(4),
                            alignment: Alignment.center,
                            badgeColor: AppThemes.currentTheme.badgeBackColor,
                            showBadge: controller.filterRequest.showBadge(),
                            position: BadgePosition.bottomStart(bottom: 2, start: 2),
                            child: Icon(IconList.filterM).whiteOrDifferentOnPrimary()),
                        onPressed: () async{
                          (await controller.onFilterOptionClick.delay()).call();

                        }
                    ),

                    /*IconButton(
                          icon: Icon(IconList.sortAscM).whiteOrDifferentOnPrimary(),
                          onPressed: () async{
                            (await controller.onSortClick.delay()).call();
                          },
                        ),*/

                    Flexible(
                      child: CheckBoxRow(
                          mainAxisSize: MainAxisSize.min,
                          tickColor: AppThemes.currentTheme.primaryColor,
                          borderColor: Colors.white,
                          value: controller.notActivePupil,
                          description: Text('${tInMap('pupilPage', 'inActivePupil')}').color(Colors.white),
                          onChanged: (v){
                            controller.notActivePupil = v;
                            appBarRefresher.update();

                            final fv = controller.filterRequest.getFilterViewFor(FilterKeys.byInActivePupilMode);
                            fv?.selectedValue = v? fv.key : null;

                            controller.resetRequest();
                          }
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        }
    );
  }

  Widget getListView() {
    return pull.RefreshConfiguration(
        headerBuilder: pullHeader,
        footerBuilder: () => pull.ClassicFooter(),
        headerTriggerDistance: 80.0,
        footerTriggerDistance: 200.0,
        //springDescription: SpringDescription(stiffness: 170, damping: 16, mass: 1.9),
        maxOverScrollExtent: 100,
        maxUnderScrollExtent: 0,
        enableScrollWhenRefreshCompleted: true, // incompatible with PageView and TabBarView.
        enableLoadingWhenFailed: true,
        hideFooterWhenNotFull: true,
        enableBallisticLoad: false,
        enableBallisticRefresh: false,
        skipCanRefresh: true,
        child: pull.SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          controller: controller.pullLoadCtr,
          onRefresh: () => controller.onRefresh(),
          onLoading: () => controller.onLoadMore(),
          footer: pullFooter(),
          child: Builder(
            builder: (context) {
              if(controller.userList.isEmpty) {
                return noStudents();
              }

              return ListView.builder(
                itemCount: controller.userList.length,
                  itemBuilder: (ctx, idx){
                    return ListBuilderPupils(
                        controller.userList[idx], controller.user, controller.listChildren,
                    key: ValueKey(controller.userList[idx].userId),);
                  }
              );
            }
          ),
        )
    );
  }

  Widget pullHeader(){
    return pull.MaterialClassicHeader(
      color: AppThemes.checkPrimaryByWB(AppThemes.currentTheme.primaryColor, AppThemes.currentTheme.differentColor),
      //refreshStyle: pull.RefreshStyle.Follow,
    );
  }

  Widget pullFooter(){
    return pull.CustomFooter(
      loadStyle: pull.LoadStyle.ShowWhenLoading,
      builder: (BuildContext context, pull.LoadStatus? state) {
        if (state == pull.LoadStatus.loading) {
          return SizedBox(
            height: 80,
            child: PreWidgets.flutterLoadingWidget$Center(),
          );
        }

        if (state == pull.LoadStatus.noMore || state == pull.LoadStatus.idle) {
          return SizedBox();
        }

        return SizedBox();
      },
    );
  }
}


