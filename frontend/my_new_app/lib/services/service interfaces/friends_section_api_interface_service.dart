import 'package:my_new_app/models/friends_model.dart';

abstract class FriendsService {
  Future<List<Friend>> fetchFriends();
  Future<bool> settleFriend(String friendUsername);
  Future<bool> remindFriend(String friendUsername);
}
