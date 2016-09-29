module Xsys
  module Model
    class Product
      def self.attr_list
        [:id, :name, :sellable, :product_category_id,
         :product_provider_id, :vat_rate, :taxed_cost, :vat_cost, :total_cost,
         :pending_ordered_quantity, :stocks, :prices, :category, :provider,
         :last_total_cost, :last_taxed_cost, :cost_update_date, :cost_update_time,
         :last_cost_update_date, :last_cost_update_time, :price_update_date, :price_update_time,
         :online_stock, :product_size_code, :weight, :length, :width, :height, :packages_quantity,
         :ean, :packages, :regular_price, :reduced_price, :credit_card_price, :brand, :model
       ]
      end

      attr_reader *attr_list

      def initialize(attributes={})
        time_fields = ['cost_update_time', 'last_cost_update_time', 'price_update_time']
        date_fields = ['cost_update_date', 'last_cost_update_date', 'price_update_date']
        decimal_fields = ['vat_rate', 'taxed_cost', 'vat_cost', 'total_cost', 'last_total_cost',
          'last_taxed_cost', 'regular_price', 'reduced_price', 'credit_card_price']

        attributes.each do |k, v|
          if k.to_s == 'category'
            @category = ProductCategory.new(v) unless v.nil?
          elsif k.to_s == 'provider'
            @provider = ProductProvider.new(v) unless v.nil?
          elsif k.to_s == 'stocks'
            @stocks = v.map { |s| Stock.new(s) } unless v.nil?
          elsif k.to_s == 'prices'
            @prices = v.map { |s| ProductPriceList.new(s) }
          elsif time_fields.include?(k.to_s)
            self.send("#{k}=", Time.parse(v)) unless v.nil?
          elsif date_fields.include?(k.to_s)
            self.send("#{k}=", Date.parse(v)) unless v.nil?
          elsif decimal_fields.include?(k.to_s)
            self.send("#{k}=", BigDecimal.new(v)) unless v.nil?
          else
            self.send("#{k}=", v) if self.respond_to?(k)
          end
        end
      end

      def sellable_stocks
        stocks.find_all { |s| !s.shop_service }
      end

      def sellable_stocks_quantity(options={})
        result = 0

        sellable_stocks.each do |stock|
          if options[:skip_exhibition]
            if !stock.shop_has_exhibition
              result += stock.quantity
            elsif stock.quantity > 0
              result += (stock.quantity - 1)
            else
              result += stock.quantity
            end
          else
            result += stock.quantity
          end
        end

        result
      end

      def service_stocks
        stocks.find_all { |s| s.shop_service }
      end

      def service_stocks_quantity
        service_stocks.map(&:quantity).sum
      end

      def stocks_quantity
        stocks.map(&:quantity).sum
      end

      def stock_sum(shop_codes)
        formatted_shop_codes = shop_codes.map(&:to_s).map(&:upcase)

        stocks.find_all { |s|
          formatted_shop_codes.include?(s.shop_code.to_s.upcase)
        }.map(&:quantity).sum
      end

      def stock_at(shop_code, options={})
        stock = stocks.find { |s|
          s.shop_code.to_s.upcase == shop_code.to_s.upcase
        }

        if options[:skip_exhibition]
          if !stock.shop_has_exhibition
            stock.quantity
          elsif stock.quantity > 0
            (stock.quantity - 1)
          else
            stock.quantity
          end
        else
          stock.quantity
        end
      end

      def price_date_for_list(price_list_id)
        prices.find { |p|
          p.price_list_id.to_i == price_list_id.to_i
        }.try(:price_update_date)
      end

      def markup_with_list(price_list_id)
        prices.find { |p|
          p.price_list_id.to_i == price_list_id.to_i
        }.try(:markup) || BigDecimal.new('0.0')
      end

      def price_in_list(price_list_id)
        prices.find { |p|
          p.price_list_id.to_i == price_list_id.to_i
        }.try(:total_price) || BigDecimal.new('0.0')
      end

      private

      attr_writer *attr_list
    end
  end
end
