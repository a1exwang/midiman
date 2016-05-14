require_relative 'note'
require_relative 'midi'

module Musel
  module Pattern

    #
    #1、C—Am—F—G 蔡琴—恰似你的温柔
    #2、C—G—Am—F Beyond—海阔天空 主歌
    #3、C—F—G—C 李健—传奇 主歌
    #4、C—G—Am—G
    #5、C—G—F—G eric clapton—wonderful tonight
    #6、C—G—F—C Coldplay—Swallowed In The Sea
    #7、C—F—C—G Coldplay—Fix you

    #1、Am—F—C—G（参考曲目：黄义达—我懂、set me free）
    #2、Am—C—G—Am（参考曲目：Beyond—灰色轨迹 主歌）
    #3、Am—F—G—Am（参考曲目：汪峰—再见青春）
    #4、Am—G—F—Am（参考曲目：我的原创—万马奔腾）
    #试听：http://music.weibo.com/t/i/100103914.html
    #5、Am—F—Am—G（参考曲目：我的原创—未知旅途的风景 主歌）
    #试听：http://music.weibo.com/t/i/100059211.html
    #6、Am—C—F—C（参考曲目：the cranberries—diying in the sun 主歌）
    #Am—G—F—G（参考曲目：扭曲的机器—三十  主歌）
    #Am—G—C—Am（参考曲目：较少，暂时没想到）

    # C G Am Em F C F G
    # 1 5 6  3  4 1 4 5
    def self.harm_1645(midi, scale)
      arr = [
          Musel::ChordHarmonics.new(3, "c#{scale}".to_sym, :quarter, 2),
          Musel::ChordHarmonics.new(3, "a#{scale-1}".to_sym, :quarter, 2),
          Musel::ChordHarmonics.new(3, "f#{scale}".to_sym, :quarter, 0),
          Musel::ChordHarmonics.new(3, "g#{scale}".to_sym, :quarter, 0)
      ]
      #puts (arr.map { |x| x.to_s }).join("\n")
      arr.each do |h|
        2.times { midi.append_harm(h) }
      end
    end

    def self.pachelbel_canon(midi, scale)
      arr = [
          Musel::ChordHarmonics.new(3, "c#{scale}".to_sym, :quarter, 2),
          Musel::ChordHarmonics.new(3, "g#{scale-1}".to_sym, :quarter, 2),
          Musel::ChordHarmonics.new(3, "a#{scale}".to_sym, :quarter, 0),
          Musel::ChordHarmonics.new(3, "e#{scale}".to_sym, :quarter, 0),
          Musel::ChordHarmonics.new(3, "f#{scale}".to_sym, :quarter, 0),
          Musel::ChordHarmonics.new(3, "c#{scale}".to_sym, :quarter, 2),
          Musel::ChordHarmonics.new(3, "f#{scale}".to_sym, :quarter, 0),
          Musel::ChordHarmonics.new(3, "g#{scale}".to_sym, :quarter, 0)
      ]
      puts "pachelbel canon, scale: #{scale}"
      puts (arr.map { |x| x.to_s }).join("\n")
      arr.each do |h|
        2.times { midi.append_harm(h) }
      end
    end


  end
end

