class User {
  constructor(dictionary) {
    this.type = dictionary.type
    this.id = dictionary.id
    this.connected = dictionary.connected
    this.message = dictionary.message
  }
}

module.exports = User
