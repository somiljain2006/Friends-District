import Foundation
var components = URLComponents(string: "https://district.monu14.me/api/v1/rooms/1/ws")!
components.scheme = "wss"
components.queryItems = [URLQueryItem(name: "user_phone", value: "+919897000000")]
print(components.url!.absoluteString)
