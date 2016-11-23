package com.rctunderdark;

public interface MessageDecoder {
    public String getDisplayName(byte[] frame);
    public  User.PeerType getType(byte[] frame);
    public String getDeviceId(byte[] frame);
    public String getMessage(byte[] frame);
}
