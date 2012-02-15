module Rapnd
  class Notification
    attr_accessor :badge, :alert, :sound, :custom, :device_token
    
    def initialize(hash)
      [:badge, :alert, :sound, :custom, :device_token].each do |k|
        self.instance_variable_set("@#{k}".to_sym, hash[k]) if hash[k]
      end
      raise 'Must provide device token' if self.device_token.nil?
      self.device_token = self.device_token.delete(' ')
    end
    
    def payload
      p = Hash.new
      [:badge, :alert, :sound, :custom].each do |k|
        p[k] = send(k) if send(k)
      end
      custom = p.delete(:custom)
      aps = {:aps => p}
      aps.merge!(:custom => custom) if custom
      aps
    end
    
    def json_payload
      j = ActiveSupport::JSON.encode(payload)
      raise PayloadInvalid.new("The payload is larger than allowed: #{j.length}") if j.size > 256
      j
    end
    
    def to_bytes
      j = json_payload
      [0, 0, 32, self.device_token, 0, j.bytesize, j].pack("cccH*cca*").force_encoding('ASCII-8BIT')
    end
  end
end