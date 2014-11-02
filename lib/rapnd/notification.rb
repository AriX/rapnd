module Rapnd
  class Notification
    attr_accessor :badge, :alert, :sound, :content_available, :category, :custom_properties, :device_token
    
    def initialize(hash)
      [:badge, :alert, :sound, :device_token, :content_available, :category, :custom_properties].each do |k|
        self.instance_variable_set("@#{k}".to_sym, hash[k]) if hash[k]
      end
      raise "Must provide device token: #{hash}" if self.device_token.nil?
      self.device_token = self.device_token.delete(' ')
    end
    
    def payload
      p = Hash.new
      [:badge, :alert, :sound, :content_available, :category].each do |k|
        p[k.to_s.gsub('_','-').to_sym] = send(k) if send(k)
      end
      aps = {:aps => p}
      aps.merge!(custom_properties) if custom_properties
      aps
    end
    
    def json_payload
      j = payload.to_json.force_encoding("utf-8")
      # raise "The payload #{j} is larger than allowed: #{j.length}" if j.size > 2048
      j
    end
    
    def item(id, size, item, encoding)
        [id, size, item].pack("Cn" + encoding)
    end
    
    def to_bytes
      j = json_payload
      devicetoken_item = self.item(1, 32, self.device_token, "H*")
      payload_item = self.item(2, j.bytesize, j, "a*").force_encoding('ASCII-8BIT')
      notificationidentifier_item = self.item(3, 4, 0, "N")
      expiration_item = self.item(4, 4, 31536000, "N")
      priority_item = self.item(5, 1, 10, "C")
      
      frame = [devicetoken_item, payload_item, notificationidentifier_item, expiration_item, priority_item].pack("a*a*a*a*a*").force_encoding('ASCII-8BIT')
      
      command = 2
      frame_length = frame.bytesize
      
      [command, frame_length, frame].pack("CNa*").force_encoding('ASCII-8BIT')
    end
  end
end