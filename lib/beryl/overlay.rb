# frozen_string_literal: true

module Beryl
  module Overlay
    module_function

    # anchor:   { x:, y:, w:, h: }（锚元素矩形；点锚用 w: 0, h: 0）
    # size:     { w:, h: } 弹层尺寸
    # viewport: { w:, h: }
    # placement: :bottom | :top | :left | :right（首选方向，放不下翻转到对侧）
    # → { x:, y:, placement: }（左上角坐标，已 shift 进视口）
    def position(anchor:, size:, viewport:, placement: :bottom)
      best = coords(anchor, size, placement)
      chosen = placement
      flipped = coords(anchor, size, flip(placement))

      unless fits?(best, size, viewport)
        if fits?(flipped, size, viewport)
          best = flipped
          chosen = flip(placement)
        end
      end

      {
        x: clamp(best[:x], 0, [viewport[:w] - size[:w], 0].max),
        y: clamp(best[:y], 0, [viewport[:h] - size[:h], 0].max),
        placement: chosen,
      }
    end

    def coords(a, s, placement)
      case placement
      when :top   then { x: a[:x], y: a[:y] - s[:h] }
      when :left  then { x: a[:x] - s[:w], y: a[:y] }
      when :right then { x: a[:x] + a[:w], y: a[:y] }
      else             { x: a[:x], y: a[:y] + a[:h] } # :bottom
      end
    end

    def flip(placement)
      case placement
      when :top then :bottom
      when :bottom then :top
      when :left then :right
      when :right then :left
      else placement
      end
    end

    def fits?(coord, size, viewport)
      coord[:x] >= 0 && coord[:y] >= 0 &&
        coord[:x] + size[:w] <= viewport[:w] &&
        coord[:y] + size[:h] <= viewport[:h]
    end

    def clamp(v, lo, hi)
      v = lo if v < lo
      v = hi if v > hi
      v
    end
  end
end
