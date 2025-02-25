import 'package:DataCareUltra/utils/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preffrance {

    void setString(String key, String text)async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString(key, text);
  }

  Future<String?> getString(String key)async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? value = await sharedPreferences.getString(key);
    return value;
  }
}