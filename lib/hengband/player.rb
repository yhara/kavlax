# coding: utf-8

module Hengband
  class Player
    EQUIP_PLACES = [:r_arm, :l_arm, :bow, :r_finger, :l_finger,
      :neck, :light, :body, :outer, :head, :hands, :feet]
    EQUIPPABLES = [[:weapon, :shield], [:weapon, :shield], [:bow],
      [:ring], [:ring], [:neck], [:light], [:armor], [:cloak],
      [:head], [:hands], [:feet]]

    def initialize(inventory = [])
      @inventory = inventory
      @equips = {}.tap{|h|
        EQUIP_PLACES.each{|name| h[name] = nil}
      }
    end
    attr_reader :equips

    def wear_random
      EQUIP_PLACES.zip(EQUIPPABLES).each do |name, types|
        item = @inventory.find_all{|x| types.include? x.type}.sample
        @equips[name] = item
      end
      self
    end

    def wearings
      i = "`"
      EQUIP_PLACES.map{|name|
        i.succ!
        "#{i}) #{@equips[name]}"
      }.join("\n")
    end

    def resists
      @equips.map{|name, x| x.flags[:res] + x.flags[:imm]}.inject(:+).uniq.join
    end

  end
end

