class PeerModel {
  constructor(dictionary) {
    this.type = dictionary.type
    this.id = dictionary.id
    this.connected = dictionary.connected
    this.message = dictionary.message
    this.renderType = "peer"
  }
}

module.exports = PeerModel
