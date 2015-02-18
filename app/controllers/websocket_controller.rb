class WebsocketController < WebsocketRails::BaseController
  def message_receive
    receive_message = message
    #broadcast_message :websocket, receive_message
    WebsocketRails[:editors].trigger :websocket, message
  end
end
