import 'dart:convert';
import 'package:date_format/date_format.dart';
import 'package:fzwmlc/model/currency_entity.dart';
import 'package:fzwmlc/model/submit_entity.dart';
import 'package:fzwmlc/utils/handler_order.dart';
import 'package:fzwmlc/utils/refresh_widget.dart';
import 'package:fzwmlc/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/time_picker/model/date_mode.dart';
import 'package:flutter_pickers/time_picker/model/pduration.dart';
import 'package:flutter_pickers/time_picker/model/suffix.dart';
import 'dart:io';
import 'package:flutter_pickers/utils/check.dart';
import 'package:flutter/cupertino.dart';
import 'package:fzwmlc/components/my_text.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RetrievalDetail extends StatefulWidget {
  var FBillNo;
  RetrievalDetail({Key? key, @required this.FBillNo}) : super(key: key);

  @override
  _RetrievalDetailState createState() => _RetrievalDetailState(FBillNo);
}

class _RetrievalDetailState extends State<RetrievalDetail> {
  var _remarkContent = new TextEditingController();
  var F_VBMY_Text1;
  var F_VBMY_Text2;
  var F_VBMY_Text3;
  var F_VBMY_Text4 = "";
  GlobalKey<PartRefreshWidgetState> globalKey = GlobalKey();
  final _textNumber = TextEditingController();
  var checkItem;
  String FBillNo = '';
  String FSaleOrderNo = '';
  String cusName = '';
  String FName = '';
  String FNumber = '';
  String FDate = '';
  var customerName;
  var customerNumber;
  var isSubmit = false;
  var show = false;
  var isScanWork = false;
  var checkData;
  var fOrgID;
  var checkDataChild;
  var selectData = {
    DateMode.YMD: '',
  };
  var customerList = [];
  List<dynamic> customerListObj = [];
  var stockList = [];
  List<dynamic> stockListObj = [];
  List<dynamic> orderDate = [];
  List<dynamic> materialDate = [];
  final divider = Divider(height: 1, indent: 20);
  final rightIcon = Icon(Icons.keyboard_arrow_right);
  static const scannerPlugin =
      const EventChannel('com.shinow.pda_scanner/plugin');
  StreamSubscription? _subscription;
  var _code;
  var _FNumber;
  var fBillNo;

  _RetrievalDetailState(FBillNo) {
    if (FBillNo != null) {
      this.fBillNo = FBillNo['value'];
      this.getOrderList();
      isScanWork = true;
    } else {
      isScanWork = false;
      this.fBillNo = '';
      getCustomer();
      getStockList();
    }
  }

  @override
  void initState() {
    super.initState();
    // 开启监听
    if (_subscription == null) {
      _subscription = scannerPlugin
          .receiveBroadcastStream()
          .listen(_onEvent, onError: _onError);
    }
    /*getWorkShop();*/
  }

  //获取客户
  getCustomer() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_Customer';
    userMap['FieldKeys'] = 'FCUSTID,FName,FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    customerListObj = jsonDecode(res);
    customerListObj.forEach((element) {
      customerList.add(element[1]);
    });
  }

  //获取仓库
  getStockList() async {
    Map<String, dynamic> userMap = Map();
    userMap['FormId'] = 'BD_STOCK';
    userMap['FieldKeys'] = 'FStockID,FName,FNumber,FIsOpenLocation';
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var deptData = jsonDecode(menuData)[0];
    if (fOrgID == null) {
      this.fOrgID = deptData[1];
    }
    userMap['FilterString'] =
        "FForbidStatus = 'A' and FUseOrgId.FNumber =" + fOrgID;
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String res = await CurrencyEntity.polling(dataMap);
    stockListObj = jsonDecode(res);
    stockListObj.forEach((element) {
      stockList.add(element[1]);
    });
  }

  void getWorkShop() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      if (sharedPreferences.getString('FWorkShopName') != null) {
        FName = sharedPreferences.getString('FWorkShopName');
        FNumber = sharedPreferences.getString('FWorkShopNumber');
        isScanWork = true;
      } else {
        isScanWork = false;
      }
    });
  }

  @override
  void dispose() {
    this._textNumber.dispose();
    super.dispose();

    /// 取消监听
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  // 查询数据集合
  List hobby = [];

  getOrderList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var fStaffNumber = sharedPreferences.getString('FStaffNumber');
    EasyLoading.show(status: 'loading...');
    Map<String, dynamic> userMap = Map();
    userMap['FilterString'] = "fBillNo='$fBillNo'";
    userMap['FormId'] = 'SAL_SaleOrder';
    userMap['FieldKeys'] =
        'FBillNo,FSaleOrgId.FNumber,FSaleOrgId.FName,FDate,FSaleOrderEntry_FEntryId,FMaterialId.FNumber,FMaterialId.FName,FMaterialId.FSpecification,FCorrespondOrgId.FNumber,FCorrespondOrgId.FName,FUnitId.FNumber,FUnitId.FName,FQty,FDeliveryDate,FRemainOutQty,FID,FCustId.FNumber,FCustId.FName,FStockID.FName,FStockID.FNumber,FLot.FNumber,FStockID.FIsOpenLocation,FMaterialId.FIsBatchManage,F_TLWD_Text,F_VBMY_Text,F_VBMY_Text1,FTaxPrice,FEntryTaxRate,FSettleCurrId.FNumber,FSaleDeptId.FNumber';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    orderDate = [];
    orderDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (orderDate.length > 0) {
      this.FBillNo = orderDate[0][0];
      this.cusName = orderDate[0][17];
      this.fOrgID = orderDate[0][8];
      this.F_VBMY_Text1 = orderDate[0][23];
      print(sharedPreferences.getString('F_VBMY_Text'));
      this.F_VBMY_Text2 = sharedPreferences.getString('F_VBMY_Text') == null
          ? ""
          : sharedPreferences.getString('F_VBMY_Text');
      this.F_VBMY_Text3 = sharedPreferences.getString('F_VBMY_Text1') == null
          ? ""
          : sharedPreferences.getString('F_VBMY_Text1');
      hobby = [];
      orderDate.forEach((value) {
        List arr = [];
        arr.add({
          "title": "单据编号",
          "name": "FBillNo",
          "isHide": true,
          "value": {"label": value[0], "value": value[0]}
        });
        arr.add({
          "title": "销售组织",
          "name": "FSaleOrgId",
          "isHide": true,
          "value": {"label": value[2], "value": value[1]}
        });
        arr.add({
          "title": "客户",
          "name": "FSaleOrgId",
          "isHide": true,
          "value": {"label": value[17], "value": value[16]}
        });
        arr.add({
          "title": "单据日期",
          "name": "FDate",
          "isHide": true,
          "value": {"label": value[3], "value": value[3]}
        });
        arr.add({
          "title": "物料名称",
          "name": "FMaterial",
          "isHide": false,
          "value": {"label": value[6], "value": value[5], "barcode": []}
        });
        arr.add({
          "title": "规格型号",
          "name": "FMaterialIdFSpecification",
          "isHide": false,
          "value": {"label": value[7], "value": value[7]}
        });
        arr.add({
          "title": "单位名称",
          "name": "FUnitId",
          "isHide": false,
          "value": {"label": value[11], "value": value[10]}
        });
        arr.add({
          "title": "未出库数量",
          "name": "FRemainOutQty",
          "isHide": false,
          "value": {"label": value[14], "value": value[14]}
        });
        arr.add({
          "title": "数量",
          "name": "FBaseQty",
          "isHide": false,
          "value": {"label": "1", "value": "1"}
        });
        arr.add({
          "title": "要货日期",
          "name": "FDeliveryDate",
          "isHide": true,
          "value": {"label": value[13], "value": value[13]}
        });
        if (fStaffNumber == "Z090" || fStaffNumber == "Z069") {
          arr.add({
            "title": "仓库",
            "name": "FStockId",
            "isHide": false,
            "value": {"label": "库存商品", "value": "CK017"}
          });
        } else if(fStaffNumber == "Z005"){
          arr.add({
            "title": "仓库",
            "name": "FStockId",
            "isHide": false,
            "value": {"label": "总仓", "value": "CK001"}
          });
        }else {
          arr.add({
            "title": "仓库",
            "name": "FStockId",
            "isHide": false,
            "value": {
              "label": value[18] == null ? "库存商品" : value[18],
              "value": value[19] == null ? "CK017" : value[19]
            }
          });
        }
        arr.add({
          "title": "批号",
          "name": "FLot",
          "isHide": value[22] != true,
          "value": {"label": value[22] ? value[23] : '', "value": value[22] ? value[23] : ''}
        });
        arr.add({
          "title": "仓位",
          "name": "FStockLocID",
          "isHide": false,
          "value": {"label": "", "value": "", "hide": value[21]}
        });
        arr.add({
          "title": "操作",
          "name": "",
          "isHide": false,
          "value": {"label": "", "value": ""}
        });
        hobby.add(arr);
      });
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
    }
    getStockList();
  }

  void _onEvent(event) async {
    _code = event;
    print("ChannelPage: $event");
    switch (checkItem) {
      case 'Batch':
        this._textNumber.text = _code;
        Navigator.pop(context);
        setState(() {
          this.hobby[checkData][checkDataChild]["value"]["label"] = _code;
          this.hobby[checkData][checkDataChild]['value']["value"] = _code;
        });
        checkItem = "";
        break;
      case 'F_VBMY_Text4':
        this._textNumber.text = _code;
        setState(() {
          this.F_VBMY_Text4 =  _code;
        });
        Navigator.pop(context);
        checkItem = "";
        break;
      default:
        this.getMaterialList();
        break;
    }
  }

  void _onError(Object error) {
    setState(() {
      _code = "扫描异常";
    });
  }

  getMaterialList() async {
    Map<String, dynamic> userMap = Map();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var menuData = sharedPreferences.getString('MenuPermissions');
    var fStaffNumber = sharedPreferences.getString('FStaffNumber');
    var deptData = jsonDecode(menuData)[0];
    var scanCode = _code.split(",");
    userMap['FilterString'] = "FNumber='" +
        scanCode[0] +
        "' and FForbidStatus = 'A' and FUseOrgId.FNumber = " +
        deptData[1];
    userMap['FormId'] = 'BD_MATERIAL';
    userMap['FieldKeys'] =
        'FMATERIALID,FName,FNumber,FSpecification,FBaseUnitId.FName,FBaseUnitId.FNumber,FIsBatchManage';
    Map<String, dynamic> dataMap = Map();
    dataMap['data'] = userMap;
    String order = await CurrencyEntity.polling(dataMap);
    materialDate = [];
    materialDate = jsonDecode(order);
    FDate = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    selectData[DateMode.YMD] = formatDate(DateTime.now(), [
      yyyy,
      "-",
      mm,
      "-",
      dd,
    ]);
    if (materialDate.length > 0) {
      var number = 0;
      for (var element in hobby) {
        //判断是否启用批号
        if (element[11]['isHide']) {
          //不启用
          if (element[4]['value']['value'] == scanCode[0]) {
            if (element[4]['value']['barcode'].indexOf(_code) == -1) {
              element[4]['value']['barcode'].add(_code);
              element[8]['value']['label'] =
                  (double.parse(element[8]['value']['label']) + 1).toString();
              element[8]['value']['value'] =
                  (double.parse(element[8]['value']['label']) + 1).toString();
              number++;
              break;
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        } else {
          if (element[4]['value']['value'] == scanCode[0]) {
            if (element[4]['value']['barcode'].indexOf(_code) == -1) {
              if (element[11]['value']['value'] == scanCode[1]) {
                element[4]['value']['barcode'].add(_code);
                element[8]['value']['label'] =
                    (double.parse(element[8]['value']['label']) + 1).toString();
                element[8]['value']['value'] =
                    (double.parse(element[8]['value']['label']) + 1).toString();
                number++;
                break;
              } else {
                if (element[11]['value']['value'] == "" ||
                    element[11]['value']['value'] == null) {
                  element[4]['value']['barcode'].add(_code);
                  element[11]['value']['label'] = scanCode[1];
                  element[11]['value']['value'] = scanCode[1];
                  element[8]['value']['label'] =
                      (double.parse(element[8]['value']['label']) + 1)
                          .toString();
                  element[8]['value']['value'] =
                      (double.parse(element[8]['value']['label']) + 1)
                          .toString();
                  number++;
                  break;
                }
              }
            } else {
              ToastUtil.showInfo('该标签已扫描');
              number++;
              break;
            }
          }
        }
      }
      ;
      if (number == 0 && this.fBillNo == "") {
        materialDate.forEach((value) {
          List arr = [];
          arr.add({
            "title": "单据编号",
            "name": "FBillNo",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "销售组织",
            "name": "FSaleOrgId",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "客户",
            "name": "FSaleOrgId",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "单据日期",
            "name": "FDate",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          arr.add({
            "title": "物料名称",
            "name": "FMaterial",
            "isHide": false,
            "value": {
              "label": value[1],
              "value": value[2],
              "barcode": [_code]
            }
          });
          arr.add({
            "title": "规格型号",
            "isHide": false,
            "name": "FMaterialIdFSpecification",
            "value": {"label": value[3], "value": value[3]}
          });
          arr.add({
            "title": "单位名称",
            "name": "FUnitId",
            "isHide": false,
            "value": {"label": value[4], "value": value[5]}
          });
          arr.add({
            "title": "出库数量",
            "name": "FRealQty",
            "isHide": false,
            "value": {"label": "0", "value": "0"}
          });
          arr.add({
            "title": "数量",
            "name": "FRemainOutQty",
            "isHide": false,
            "value": {"label": "1", "value": "1"}
          });
          arr.add({
            "title": "要货日期",
            "name": "FDeliveryDate",
            "isHide": true,
            "value": {"label": "", "value": ""}
          });
          if (fStaffNumber == "Z090" || fStaffNumber == "Z069") {
            arr.add({
              "title": "仓库",
              "name": "FStockId",
              "isHide": false,
              "value": {"label": "库存商品", "value": "CK017"}
            });
          } else if(fStaffNumber == "Z005"){
            arr.add({
              "title": "仓库",
              "name": "FStockId",
              "isHide": false,
              "value": {"label": "总仓", "value": "CK001"}
            });
          }else {
            arr.add({
              "title": "仓库",
              "name": "FStockID",
              "isHide": false,
              "value": {"label": "", "value": ""}
            });
          }
          arr.add({
            "title": "批号",
            "name": "FLot",
            "isHide": value[6] != true,
            "value": {
              "label": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : '',
              "value": value[6] ? (scanCode.length > 1 ? scanCode[1] : '') : ''
            }
          });
          arr.add({
            "title": "仓位",
            "name": "FStockLocID",
            "isHide": false,
            "value": {"label": "", "value": "", "hide": false}
          });
          arr.add({
            "title": "操作",
            "name": "",
            "isHide": false,
            "value": {"label": "", "value": ""}
          });
          hobby.add(arr);
        });
      }
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
    } else {
      setState(() {
        EasyLoading.dismiss();
        this._getHobby();
      });
      ToastUtil.showInfo('无数据');
    }
  }

  Widget _item(title, var data, selectData, hobby, {String? label, var stock}) {
    if (selectData == null) {
      selectData = "";
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () => data.length > 0
                ? _onClickItem(data, selectData, hobby,
                    label: label, stock: stock)
                : {ToastUtil.showInfo('无数据')},
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              MyText(selectData.toString() == "" ? '暂无' : selectData.toString(),
                  color: Colors.grey, rightpadding: 18),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  Widget _dateItem(title, model) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(title),
            onTap: () {
              _onDateClickItem(model);
            },
            trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              PartRefreshWidget(globalKey, () {
                //2、使用 创建一个widget
                return MyText(
                    (PicketUtil.strEmpty(selectData[model])
                        ? '暂无'
                        : selectData[model])!,
                    color: Colors.grey,
                    rightpadding: 18);
              }),
              rightIcon
            ]),
          ),
        ),
        divider,
      ],
    );
  }

  void _onDateClickItem(model) {
    Pickers.showDatePicker(
      context,
      mode: model,
      suffix: Suffix.normal(),
      // selectDate: PDuration(month: 2),
      minDate: PDuration(year: 2020, month: 2, day: 10),
      maxDate: PDuration(second: 22),
      selectDate: (FDate == '' || FDate == null
          ? PDuration(year: 2021, month: 2, day: 10)
          : PDuration.parse(DateTime.parse(FDate))),
      // minDate: PDuration(hour: 12, minute: 38, second: 3),
      // maxDate: PDuration(hour: 12, minute: 40, second: 36),
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        setState(() {
          switch (model) {
            case DateMode.YMD:
              selectData[model] = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              FDate = formatDate(
                  DateFormat('yyyy-MM-dd')
                      .parse('${p.year}-${p.month}-${p.day}'),
                  [
                    yyyy,
                    "-",
                    mm,
                    "-",
                    dd,
                  ]);
              break;
          }
        });
      },
      // onChanged: (p) => print(p),
    );
  }

  void _onClickItem(var data, var selectData, hobby,
      {String? label, var stock}) {
    Pickers.showSinglePicker(
      context,
      data: data,
      selectData: selectData,
      pickerStyle: DefaultPickerStyle(),
      suffix: label,
      onConfirm: (p) {
        print('longer >>> 返回数据：$p');
        print('longer >>> 返回数据类型：${p.runtimeType}');
        setState(() {
          if (hobby == 'customer') {
            customerName = p;
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                customerNumber = customerListObj[elementIndex][2];
              }
              elementIndex++;
            });
          } else {
            setState(() {
              hobby['value']['label'] = p;
            });
            var elementIndex = 0;
            data.forEach((element) {
              if (element == p) {
                hobby['value']['value'] = stockListObj[elementIndex][2];
                stock[12]['value']['hide'] = stockListObj[elementIndex][3];
              }
              elementIndex++;
            });
          }
        });
      },
    );
  }

  List<Widget> _getHobby() {
    List<Widget> tempList = [];
    for (int i = 0; i < this.hobby.length; i++) {
      List<Widget> comList = [];
      for (int j = 0; j < this.hobby[i].length; j++) {
        if (!this.hobby[i][j]['isHide']) {
          if (j == 8 || j == 11) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              icon: new Icon(Icons.filter_center_focus),
                              tooltip: '点击扫描',
                              onPressed: () {
                                if (j == 11) {
                                  checkItem = 'Batch';
                                }
                                this._textNumber.text =
                                    this.hobby[i][j]["value"]["label"];
                                this._FNumber =
                                    this.hobby[i][j]["value"]["label"];
                                checkData = i;
                                checkDataChild = j;
                                scanDialog();
                                if (this.hobby[i][j]["value"]["label"] != 0) {
                                  this._textNumber.value =
                                      _textNumber.value.copyWith(
                                    text: this.hobby[i][j]["value"]["label"],
                                  );
                                }
                              },
                            ),
                          ])),
                ),
                divider,
              ]),
            );
          } else if (j == 10) {
            comList.add(
              _item('仓库:', stockList, this.hobby[i][j]['value']['label'],
                  this.hobby[i][j],
                  stock: this.hobby[i]),
            );
          } else if (j == 12) {
            comList.add(
              Visibility(
                maintainSize: false,
                maintainState: false,
                maintainAnimation: false,
                visible: this.hobby[i][j]["value"]["hide"],
                child: Column(children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                        title: Text(this.hobby[i][j]["title"] +
                            '：' +
                            this.hobby[i][j]["value"]["label"].toString()),
                        trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                icon: new Icon(Icons.filter_center_focus),
                                tooltip: '点击扫描',
                                onPressed: () {
                                  this._textNumber.text = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  this._FNumber = this
                                      .hobby[i][j]["value"]["label"]
                                      .toString();
                                  checkItem = 'FNumber';
                                  this.show = false;
                                  checkData = i;
                                  checkDataChild = j;
                                  scanDialog();
                                  print(this.hobby[i][j]["value"]["label"]);
                                  if (this.hobby[i][j]["value"]["label"] != 0) {
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: this
                                          .hobby[i][j]["value"]["label"]
                                          .toString(),
                                    );
                                  }
                                },
                              ),
                            ])),
                  ),
                  divider,
                ]),
              ),
            );
          } else if (j == 13) {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                      title: Text(this.hobby[i][j]["title"] +
                          '：' +
                          this.hobby[i][j]["value"]["label"].toString()),
                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new MaterialButton(
                              color: Colors.red,
                              textColor: Colors.white,
                              child: new Text('删除'),
                              onPressed: () {
                                this.hobby.removeAt(i);
                                setState(() {});
                              },
                            )
                          ])),
                ),
                divider,
              ]),
            );
          } else {
            comList.add(
              Column(children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(this.hobby[i][j]["title"] +
                        '：' +
                        this.hobby[i][j]["value"]["label"].toString()),
                    trailing:
                        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      /* MyText(orderDate[i][j],
                        color: Colors.grey, rightpadding: 18),*/
                    ]),
                  ),
                ),
                divider,
              ]),
            );
          }
        }
      }
      tempList.add(
        SizedBox(height: 10),
      );
      tempList.add(
        Column(
          children: comList,
        ),
      );
    }
    return tempList;
  }

  //调出弹窗 扫码
  void scanDialog() {
    showDialog<Widget>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  /*  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('输入数量',
                        style: TextStyle(
                            fontSize: 16, decoration: TextDecoration.none)),
                  ),*/
                  Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Card(
                          child: Column(children: <Widget>[
                        TextField(
                          style: TextStyle(color: Colors.black87),
                          keyboardType: TextInputType.number,
                          controller: this._textNumber,
                          decoration: InputDecoration(hintText: "输入"),
                          onChanged: (value) {
                            setState(() {
                              this._FNumber = value;
                            });
                          },
                        ),
                      ]))),
                  Padding(
                    padding: EdgeInsets.only(top: 15, bottom: 8),
                    child: FlatButton(
                        color: Colors.grey[100],
                        onPressed: () {
                          // 关闭 Dialog
                          Navigator.pop(context);
                          setState(() {
                            if (checkItem == "F_VBMY_Text1") {
                              F_VBMY_Text1 = _FNumber;
                            } else if (checkItem == "F_VBMY_Text2") {
                              F_VBMY_Text2 = _FNumber;
                            } else if (checkItem == "F_VBMY_Text4") {
                              F_VBMY_Text4 = _FNumber;
                            } else if (checkItem == "F_VBMY_Text3") {
                              F_VBMY_Text3 = _FNumber;
                            } else {
                              this.hobby[checkData][checkDataChild]["value"]
                                  ["label"] = _FNumber;
                              this.hobby[checkData][checkDataChild]['value']
                                  ["value"] = _FNumber;
                            }
                            checkItem = "";
                          });
                        },
                        child: Text(
                          '确定',
                        )),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    ).then((val) {
      print(val);
    });
  }

  //保存
  saveOrder() async {
    if (this.hobby.length > 0) {
      setState(() {
        this.isSubmit = true;
      });
      Map<String, dynamic> dataMap = Map();
      dataMap['formid'] = 'SAL_OUTSTOCK';
      Map<String, dynamic> orderMap = Map();
      orderMap['NeedReturnFields'] = [];
      orderMap['IsDeleteEntry'] = false;
      Map<String, dynamic> Model = Map();
      Model['FID'] = 0;
      Model['FBillType'] = {"FNUMBER": "CKD01_SYS"};
      Model['FDate'] = FDate;
      //获取登录信息
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var menuData = sharedPreferences.getString('MenuPermissions');
      var deptData = jsonDecode(menuData)[0];
      //判断有源单 无源单
      if (this.isScanWork) {
        Model['FStockOrgId'] = {"FNumber": orderDate[0][1].toString()};
        Model['FSaleOrgId'] = {"FNumber": orderDate[0][1].toString()};
        Model['FCustomerID'] = {"FNumber": orderDate[0][16].toString()};
        Model['FSaleDeptID '] = {"FNumber": orderDate[0][29].toString()};
        /* Model['F_TLWD_Text'] = orderDate[0][23];
        Model['F_VBMY_Text '] = orderDate[0][24];
        Model['F_VBMY_Text1'] = orderDate[0][25];*/
        Model['F_TLWD_Text'] = this.F_VBMY_Text1;
        Model['F_VBMY_Text'] = this.F_VBMY_Text2;
        Model['F_VBMY_Text1'] = this.F_VBMY_Text3;
        Model['F_VBMY_Text2'] = this.F_VBMY_Text4;
      } else {
        if (this.customerNumber == null) {
          this.isSubmit = false;
          ToastUtil.showInfo('请选择客户');
          return;
        }
        Model['FStockOrgId'] = {"FNumber": this.fOrgID};
        Model['FSaleOrgId'] = {"FNumber": this.fOrgID};
        Model['FCustomerID'] = {"FNumber": this.customerNumber};
      }
      var FEntity = [];
      var hobbyIndex = 0;
      this.hobby.forEach((element) {
        if (element[8]['value']['value'] != '0' &&
            element[10]['value']['value'] != '') {
          Map<String, dynamic> FEntityItem = Map();
          FEntityItem['FMaterialId'] = {
            "FNumber": element[4]['value']['value']
          };
          FEntityItem['FTaxPrice'] = orderDate[hobbyIndex][26];
          FEntityItem['FEntryTaxRate'] = orderDate[hobbyIndex][27];
          FEntityItem['FUnitID'] = {"FNumber": element[6]['value']['value']};
          /*FEntityItem['FReturnType'] = 1;*/
          FEntityItem['FLot'] = {"FNumber": element[11]['value']['value']};
          FEntityItem['FStockID'] = {"FNumber": element[10]['value']['value']};
          FEntityItem['FStockStatusId'] = {"FNumber": "KCZT01_SYS"};
          FEntityItem['FStockLocId'] = {
            "FSTOCKLOCID__FF100011": {"FNumber": element[13]['value']['value']}
          };
          FEntityItem['FRealQty'] = element[8]['value']['value'];
          FEntityItem['FEntity_Link'] = [
            {
              "FEntity_Link_FRuleId": "SaleOrder-OutStock",
              "FEntity_Link_FSTableName": "T_SAL_ORDERENTRY",
              "FEntity_Link_FSBillId": orderDate[hobbyIndex][15],
              "FEntity_Link_FSId": orderDate[hobbyIndex][4],
              "FEntity_Link_FSALBASEQTY": element[8]['value']['value']
            }
          ];
          FEntity.add(FEntityItem);
        }
        hobbyIndex++;
      });
      if (FEntity.length == 0) {
        this.isSubmit = false;
        ToastUtil.showInfo('请输入数量,仓库');
        return;
      }
      Model['FEntity'] = FEntity;
      Model['SubHeadEntity'] = {
        'FSettleCurrID': {"FNumber": orderDate[0][28]}
      };
      orderMap['Model'] = Model;
      dataMap['data'] = orderMap;
      print(jsonEncode(dataMap));
      String order = await SubmitEntity.save(dataMap);
      var res = jsonDecode(order);
      print(res);
      if (res['Result']['ResponseStatus']['IsSuccess']) {
        Map<String, dynamic> submitMap = Map();
        submitMap = {
          "formid": "SAL_OUTSTOCK",
          "data": {
            'Ids': res['Result']['ResponseStatus']['SuccessEntitys'][0]['Id']
          }
        };
        //提交
        HandlerOrder.orderHandler(context, submitMap, 1, "SAL_OUTSTOCK",
                SubmitEntity.submit(submitMap))
            .then((submitResult) {
          if (submitResult) {
            //审核
            HandlerOrder.orderHandler(context, submitMap, 1, "SAL_OUTSTOCK",
                    SubmitEntity.audit(submitMap))
                .then((auditResult) {
              if (auditResult) {
                sharedPreferences.setString('F_VBMY_Text', this.F_VBMY_Text2);
                sharedPreferences.setString('F_VBMY_Text1', this.F_VBMY_Text3);
                //提交清空页面
                setState(() {
                  this.hobby = [];
                  this.orderDate = [];
                  this.FBillNo = '';
                  ToastUtil.showInfo('提交成功');
                  Navigator.of(context).pop("refresh");
                });
              } else {
                //失败后反审
                HandlerOrder.orderHandler(context, submitMap, 0, "SAL_OUTSTOCK",
                        SubmitEntity.unAudit(submitMap))
                    .then((unAuditResult) {
                  if (unAuditResult) {
                    this.isSubmit = false;
                  }
                });
              }
            });
          } else {
            this.isSubmit = false;
          }
        });
      } else {
        setState(() {
          this.isSubmit = false;
          ToastUtil.errorDialog(
              context, res['Result']['ResponseStatus']['Errors'][0]['Message']);
        });
      }
    } else {
      ToastUtil.showInfo('无提交数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterEasyLoading(
      child: Scaffold(
          appBar: AppBar(
            title: Text("销售出库"),
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop("refresh");
                }),
          ),
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(children: <Widget>[
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: Text("单号：$FBillNo"),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: isScanWork,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: ListTile(
                            /* title: TextWidget(FBillNoKey, '生产订单：'),*/
                            title: Text("客户：$cusName"),
                          ),
                        ),
                        divider,
                      ],
                    ),
                  ),
                  _dateItem('日期：', DateMode.YMD),
                  Visibility(
                    maintainSize: false,
                    maintainState: false,
                    maintainAnimation: false,
                    visible: !isScanWork,
                    child: _item('客户:', this.customerList, this.customerName,
                        'customer'),
                  ),
                  Column(children: [
                    Container(
                      color: Colors.white,
                      child: ListTile(
                          title: Text("订单号：$F_VBMY_Text1"),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.create),
                                  tooltip: '输入',
                                  onPressed: () {
                                    checkItem = 'F_VBMY_Text1';
                                    this._textNumber.clear();
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: F_VBMY_Text1,
                                    );
                                    scanDialog();
                                  },
                                ),
                              ])),
                    ),
                    divider,
                  ]),
                  Column(children: [
                    Container(
                      color: Colors.white,
                      child: ListTile(
                          title: Text("运单号：$F_VBMY_Text4"),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.create),
                                  tooltip: '输入',
                                  onPressed: () {
                                    checkItem = 'F_VBMY_Text4';
                                    this._textNumber.clear();
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: F_VBMY_Text4,
                                    );
                                    scanDialog();
                                  },
                                ),
                              ])),
                    ),
                    divider,
                  ]),
                  Column(children: [
                    Container(
                      color: Colors.white,
                      child: ListTile(
                          title: Text("尺寸：$F_VBMY_Text2"),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.create),
                                  tooltip: '输入',
                                  onPressed: () {
                                    checkItem = 'F_VBMY_Text2';
                                    this._textNumber.clear();
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: F_VBMY_Text2,
                                    );
                                    scanDialog();
                                  },
                                ),
                              ])),
                    ),
                    divider,
                  ]),
                  Column(children: [
                    Container(
                      color: Colors.white,
                      child: ListTile(
                          title: Text("重量：$F_VBMY_Text3"),
                          trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                IconButton(
                                  icon: new Icon(Icons.create),
                                  tooltip: '输入',
                                  onPressed: () {
                                    checkItem = 'F_VBMY_Text3';
                                    this._textNumber.clear();
                                    this._textNumber.value =
                                        _textNumber.value.copyWith(
                                      text: F_VBMY_Text3,
                                    );
                                    scanDialog();
                                  },
                                ),
                              ])),
                    ),
                    divider,
                  ]),
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          title: TextField(
                            //最多输入行数
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: "备注",
                              //给文本框加边框
                              border: OutlineInputBorder(),
                            ),
                            controller: this._remarkContent,
                            //改变回调
                            onChanged: (value) {
                              setState(() {
                                _remarkContent.value = TextEditingValue(
                                    text: value,
                                    selection: TextSelection.fromPosition(
                                        TextPosition(
                                            affinity: TextAffinity.downstream,
                                            offset: value.length)));
                              });
                            },
                          ),
                        ),
                      ),
                      divider,
                    ],
                  ),
                  Column(
                    children: this._getHobby(),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(15.0),
                        child: Text("保存"),
                        color: this.isSubmit
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                        textColor: Colors.white,
                        onPressed: () async =>
                            this.isSubmit ? null : saveOrder(),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )),
    );
  }
}
