module Arcenciel
  class Device
    class InvalidDeviceError < StandardError; end

    include Logging

    attr_reader :id
    attr_reader :type
    attr_reader :port
    attr_reader :size

    attr_reader :control

    def initialize(id, type, port)
      @id = id
      @type = type
      @port = port
      @is_arc, @size = parse_type(type)

      @valid = false
      @control = nil

      @client = OSC::Client.new('localhost', port)
    end

    def arc?
      !!@is_arc
    end

    def attached?
      !!@control
    end

    def valid?
      !!@valid
    end

    def validate!
      raise InvalidDeviceError unless valid?
    end

    def start!(server_port)
      log_info "Adding device (#{id}; UDP #{port})..."
      set_destination(server_port)
      @valid = true
      ring_clear_all      
    end

    def stop!
      log_info "Removing device (#{id}; UDP #{port})..."
      unassign_control!
      @valid = false
    end

    def attach!(control)
      validate!
      @control = control
    end

    def ring_clear_all
      validate!
      (0...size).each do |i|
        ring_clear(i)
      end
    end

    def ring_clear(index)
      validate!
      ring_all(index, 0)
    end

    def ring_set(index, x, level)
      validate!
      @client.send(OSC::Message.new('/arc/ring/set', index, x, level))
    end

    def ring_all(index, level)
      validate!
      @client.send(OSC::Message.new('/arc/ring/all', index, level))
    end

    def ring_map(index, array)
      validate!
      @client.send(OSC::Message.new('/arc/ring/map', index, *array))
    end

    def ring_range(index, x1, x2, level)
      validate!
      @client.send(OSC::Message.new('/arc/ring/range', index, x1, x2, level))
    end

    def on_delta(index, delta)
      @control && @control.on_delta(index, delta)
    end

    def on_key(index, state)
      @control && @control.on_key(index, state)
    end
    
    private

    def set_destination(port)
      @client.send(OSC::Message.new('/sys/prefix', 'arc'))
      @client.send(OSC::Message.new('/sys/host', 'localhost'))
      @client.send(OSC::Message.new('/sys/port', port))
    end

    def unassign_control!
      @control && @control.unassign!
      @control = nil
    end

    def parse_type(type)
      m = type.match(/monome arc (\d+)/)
      m ? [true , m[1].to_i] : [false, nil]
    end
  end
end
