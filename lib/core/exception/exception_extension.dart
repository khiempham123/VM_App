import 'package:vm_first_app/core/core.dart';
import 'package:easy_localization/easy_localization.dart';

extension ErrorContentParser on Failure {
  String get localizedCode {
    final codeTr = 'err.$code';
    if (codeTr.trExists()) return codeTr.tr();

    return '';
  }

  String get localizedMessage {
    final errorTr = 'err.${error.toLowerCase()}';
    if (errorTr.trExists()) return errorTr.tr();

    return message?.tr() ?? errorTr;
  }
}
