
import 'package:get/get.dart';
import 'package:orland_sports/extension/validation.dart';

class ValidationService {
  //private constructor
  ValidationService._privateConstructor();

  //singleton instance variable
  static ValidationService? _instance;

  //This code ensures that the singleton instance is created only when it's accessed for the first time.
  //Subsequent calls to ValidationService.instance will return the same instance that was created before.

  //getter to access the singleton instance
  static ValidationService get instance {
    _instance ??= ValidationService._privateConstructor();
    return _instance!;
  }

  //empty validator
  String? emptyValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'field_required'.tr;
    }
    return null;
  }

  //email validator
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_email_validation'.tr;
    } else if (value.isValidEmail() == false) {
      return 'invalid_email'.tr;
    } else {
      return null;
    }
  }

  //username validator
  String? userNameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_username'.tr;
    } else if (value.isValidUsername() == false) {
      return 'invalid_username'.tr;
    } else {
      return null;
    }
  }

  //password validator
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'password_required'.tr;
    }

    // Disallow passwords that are only whitespace (e.g. "     ")
    // if (password.trim().isEmpty) {
    //   return 'Password cannot contain only spaces';
    // }

    if (password.length < 8) {
      return 'password_min_8_chars'.tr;
    }

    if (password.isUpperCase() == false) {
      return 'password_uppercase'.tr;
    }

    if (password.isLowerCase() == false) {
      return 'password_lowercase'.tr;
    }

    if (password.isContainDigit() == false) {
      return 'password_digit'.tr;
    }

    if (password.isContainSpecialCharacter() == false) {
      return 'password_special_char'.tr;
    }

    return null; // Return null if the password is valid
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_password'.tr;
    }

    if (value.trim().isEmpty) {
      return 'password_no_spaces'.tr;
    }

    if (value.length < 8) {
      return 'password_min_8'.tr;
    }
    return null;
  }

  String? validateMatchPassword(String value, String password) {
    if (value.isEmpty) {
      return 'please_enter_password'.tr;
    }

    if (value.trim().isEmpty) {
      return 'password_no_spaces'.tr;
    }

    if (value.length < 8) {
      return 'password_min_8'.tr;
    } else if (value != password) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }
}

// validate price with dollar sign
String? validatePrice(String? value) {
  if (value == null || value.isEmpty) {
    return 'please_enter_price'.tr;
  }
  if (!RegExp(r'^\d+$').hasMatch(value)) {
    return 'invalid_price'.tr;
  }
  return null;
}
