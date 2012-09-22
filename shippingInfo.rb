require 'fedex'
require 'shipping'
    

class ShippingInfo

def Shipping_Info (fromZipCode, toZipCode, weight)

fedex = Fedex::Shipment.new(:key => 'Uo5ehu0ZVJIkwN4y',
                            :password => 'KXOH9K5coupax3FF4bM1opp9M',
                            :account_number => '510087046',
                            :meter => '118564789',
                            :mode => 'test')
                            
ups = Shipping::UPS.new :zip => "#{toZipCode}", 
                        :sender_zip => "#{fromZipCode}", 
                        :weight => 15, 
                        :ups_license_number => "9CA349F0CB25A9DB", 
                        :ups_user =>"piyushkp", 
                        :ups_password =>"Admin123#",
                        :mode => 'test'

shipper = { :name => "Sender",
            :company => "Catprint",
            :phone_number => "555-555-5555",
            :address => "None",
            :city => "None",
            :state => Shipping::Base.state_from_zip("#{fromZipCode}"),
            :postal_code => "#{fromZipCode}",
            :country_code => "US" 
          }
            
recipient = { :name => "Recipient",
              :company => "Company",
              :phone_number => "555-555-5555",
              :address => "Main Street",
              :city => "None",
              :state => Shipping::Base.state_from_zip("#{toZipCode}"),
              :postal_code => "#{toZipCode}",
              :country_code => "US",
              :residential => "false" 
            }
              
packages = []
packages << {
  :weight => {:units => "LB", :value => weight},
  :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
}

shipping_details = {
  :packaging_type => "YOUR_PACKAGING",
  :drop_off_type => "REGULAR_PICKUP"
}

rate = fedex.rate(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_details => shipping_details)
                 
       
ship = fedex.ship(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_details => shipping_details)
                  

shippingInfo = { "Fedex Price" => rate.total_net_charge,  
              "Fedex ground_transit" => ship[:completed_shipment_detail][:operational_detail] [:transit_time],
              "UPS Price" => ups.price
            } 

return shippingInfo

end
end

my_object = ShippingInfo.new
results = my_object.Shipping_Info "48503", "12776", "10"

puts results



                  