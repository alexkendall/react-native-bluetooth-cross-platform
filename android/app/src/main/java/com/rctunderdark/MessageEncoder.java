package com.rctunderdark;

import io.underdark.transport.Link;

public interface MessageEncoder {
    public void informConnected(User user);
    public void informAccepted(User user);
    public void informDisconnected(User user);
    public void informAcceptedInvite(User user);
    public void inviteUser(User user);
    public void broadcastType();
    public void sendMessage(String message, Link link);
    public void sendMessage(String message, String id);
}
