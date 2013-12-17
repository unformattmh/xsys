module Xsys
  module Model
    class ProductProvider
      attr_accessor :id, :name, :address, :zip_code,
        :phone, :cuit, :active, :kind

      def initialize(attributes={})
        attributes.each do |k,v|
          self.send("#{k}=", v)
        end
      end
    end
  end
end
