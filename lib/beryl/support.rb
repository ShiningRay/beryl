# frozen_string_literal: true

module Beryl
  # 定时器：L2 只依赖这里的抽象（纯 CRuby，无 JS）。
  # Opal 后端由 L1 renderer 在加载时注入（setTimeout/clearTimeout）；
  # CRuby 测试可注入同步后端：Beryl::Timer.backend = ->(ms, blk) { blk.call }
  module Timer
    class << self
      # ->(ms, blk) → handle
      attr_accessor :backend
      # ->(handle)
      attr_accessor :cancel_backend

      def after(ms, &blk)
        backend ? backend.call(ms, blk) : nil
      end

      def cancel(handle)
        cancel_backend&.call(handle) if handle
      end
    end
  end

  # 数据拖放的传输通道：dragstart 存、drop 取（同文档内有效）。
  # 不走 dataTransfer 序列化，payload 可以是任意 Ruby 对象（数组/Signal/模型）。
  module DragBus
    class << self
      attr_accessor :current

      def take
        payload = @current
        @current = nil
        payload
      end
    end
  end

  # 全局 z 序分配器：浮层/窗口从同一计数器取值，后开者在上。
  # WindowManager 的窗口 z 另按注册顺序计算，不占用此计数器。
  def self.next_z
    @z_counter = (@z_counter ||= 2000) + 1
  end

  # 哈希取键：兼容 symbol / string 键（Menu items 等公共数据契约）
  def self.pick(hash, key)
    hash[key] || hash[key.to_s] || hash[key.to_sym]
  end
end
