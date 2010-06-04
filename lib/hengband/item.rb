# coding: utf-8

module Hengband
  class Item
    include Comparable

    RE_HEADER = /\w\) /
    RE_NUMBER = /\d+([本巻服冊着振足枚つ個]|切れ)の /
    RE_NAME = /(?<name>.+?) ?/
    RE_BOW = /\(x(?<bow_pow>\d+)\) ?/
    RE_DICE = /\((?<dice_num>\d+)d(?<dice_val>\d+)\) ?/
    RE_OFFENSE = /\((?<off_acc>[+-]\d+)(,(?<off_dam>[+-]\d+))?\) ?/
    RE_DEFENSE = /\[((?<def_base>\d+),)?(?<def_plus>[+-]\d+)\] ?/
    RE_PVAL = /\((?<pval>[+-]\d+).*?\) ?/
    RE_FLAGS = /\{(?<flags>.*?)\}/

    UNIDENTIFIED = /\{特別製|高級品|上質|並\}/
    REXP_ITEM = /#{RE_HEADER}#{RE_NUMBER}?#{RE_NAME
      }#{RE_BOW}?#{RE_DICE}?#{RE_OFFENSE}?#{RE_DEFENSE}?#{RE_PVAL}?#{RE_FLAGS}?$/

    def self.parse_file(path)
      in_list = false
      File.open(path, "r:euc-jp:utf-8"){|f| f.read}.lines.map{|line|
        case line
        when /\[キャラクタの装備\]/
          in_list = true
          nil
        when UNIDENTIFIED
          nil
        when REXP_ITEM
          Item.new(line) if in_list
        when /\[博物館のアイテム\]/
          in_list = false
          nil
        else
          #$stderr.puts line.encode("utf-8")
        end
      }.compact
    end

    def initialize(line)
      @line = line.chomp
      REXP_ITEM.match(@line) do |m|
        @name = m[:name]
        @bow_pow  = m[:bow_pow]  && m[:bow_pow].to_i
        @dice_num = m[:dice_num] && m[:dice_num].to_i
        @dice_val = m[:dice_val] && m[:dice_val].to_i
        @off_acc  = m[:off_acc]  && m[:off_acc].to_i
        @off_dam  = m[:off_dam]  && m[:off_dam].to_i
        @def_base = m[:def_base] && m[:def_base].to_i
        @def_plus = m[:def_plus] && m[:def_plus].to_i
        @pval     = m[:pval]     && m[:pval].to_i
        @flags = parse_flags(m[:flags])
        @type = guess_type(@name)
      end
    end
    attr_reader :line, :name, :type, :flags
    attr_reader :bow_pow, :dice_num, :dice_val, :off_acc, :off_dam,
      :def_base, :def_plus, :pval

    TYPES = [:weapon, :shield, :bow, :ring, :neck, :light,
      :armor, :cloak, :head, :hands, :feet, :other]

    def defence
      @def_plus and (@def_base + @def_plus)
    end

    def defence?
      [:shield, :armor, :cloak, :head, :hands, :feet].include? @type
    end

    def damage
      @dice_num and (@dice_num * (@dice_val/2.0) + @off_dam)
    end

    def to_s
      [ @name, " ",
         ("{r#{flags[:res].join}}" unless flags[:res].empty?),
      ].join
    end

    def <=>(other)
      if @type != other.type
        TYPES.index(@type).to_i - TYPES.index(other.type).to_i
      else
        case 
        when defence?
          other.defence - self.defence
        when @type == :weapon
          other.damage - self.damage
        else
          0
        end
      end
    end

    private

    RE_CURSED = /呪われている, /
    RE_PLUS  = /\+([攻速腕知賢器耐魅道隠探赤掘]+)/
    RE_IMM   = /\*([酸電火冷]+)/
    RE_RES   = /r([酸電火冷毒閃暗破盲乱轟獄因沌劣恐]+)/
    RE_MISC  = /;([易減投反麻視経遅活浮明警倍射瞬怒祝忌]+)/
    RE_AURA  = /\[([炎電冷魔瞬]+)/
    RE_BRAND = /\|([酸電焼凍毒沌吸震切理]+)/
    RE_KILL  = /X([邪人龍オト巨デ死動]+)/
    RE_SLAY  = /\/([邪人龍オト巨デ死動]+)/
    RE_ESP   = /~([感邪善無個人竜オト巨デ死動]+)/
    RE_SUST  = /\(([腕知賢器耐魅]+)/

    def parse_flags(str)
      Hash.new{ [] }.tap{|h|
        h[:plus]  = $1.chars.to_a if RE_PLUS =~ str
        h[:imm]   = $1.chars.to_a if RE_IMM =~ str
        h[:res]   = $1.chars.to_a if RE_RES =~ str
        h[:misc]  = $1.chars.to_a if RE_MISC =~ str
        h[:aura]  = $1.chars.to_a if RE_AURA =~ str
        h[:brand] = $1.chars.to_a if RE_BRAND =~ str
        h[:kill]  = $1.chars.to_a if RE_KILL =~ str
        h[:slay]  = $1.chars.to_a if RE_SLAY =~ str
        h[:esp]   = $1.chars.to_a if RE_ESP =~ str
        h[:sust]  = $1.chars.to_a if RE_SUST =~ str
      }
    end

    def guess_type(name)
      case name
      when /パイク|グレイブ|ダガー|マン・ゴーシュ|サーベル|クレイモア|シミター|ブレード|ソード|カタナ|メイス|スピア|トライデント|クォータースタッフ|ウォー・ハンマー|アックス|ムチ|シャベル|つるはし|脇差し|大鎌|薙刀|鉄棒|忍者刀|青龍刀|六尺棒/
        :weapon
      when /シールド|盾|鏡/
        :shield
      when /スリング|・ボウ|クロスボウ|弓|進化する銃/
        :bow
      when /指輪/
        :ring
      when /アミュレット|ペンダント|首飾り|首輪/
        :neck
      when /のランプ|石|星|白熱灯|玻璃瓶|勾玉/
        :light
      when /ジャケット|メイル|アーマー|[^グ]ローブ|よろい|かたびら|胴丸/
        :armor
      when /クローク/
        :cloak
      when /ヘルメット|ヘルム|帽子|兜|笠|冠/
        :head
      when /ガントレット|グローブ|セスタス/
        :hands
      when /靴|ブーツ/
        :feet
      else
        :other
      end
    end
  end
end
