import Foundation

extension String {
  func getIndexOf(substring: String) -> Int? {
    let subLength = substring.characters.count
    let length = self.characters.count
    if(subLength > length) {
      return nil;
    }
    for i in 0..<(length - subLength) {
      let sample = self.substringWithRange(self.startIndex.advancedBy(i)..<self.startIndex.advancedBy(i + subLength))
      if substring == sample {
        return i
      }
    }
    return nil
  }
}