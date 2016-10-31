import Foundation

extension String {
  func getIndexOf(_ substring: String) -> Int? {
    let subLength = substring.characters.count
    let length = self.characters.count
    if(subLength > length) {
      return nil;
    }
    for i in 0..<(length - subLength) {
      let sample = self.substring(with: self.characters.index(self.startIndex, offsetBy: i)..<self.characters.index(self.startIndex, offsetBy: i + subLength))
      if substring == sample {
        return i
      }
    }
    return nil
  }
}
