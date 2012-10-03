require 'fedex'    

class ShippingInfo

def Shipping_Info (fromZipCode, toZipCode, weight)

# Fedex Info
fedex = Fedex::Shipment.new(  :key => 'Uo5ehu0ZVJIkwN4y',
                              :password => 'KXOH9K5coupax3FF4bM1opp9M',
                              :account_number => '510087046',
                              :meter => '118564789',
                              :mode => 'test'
                            )
                            
shipper = { :name => "Sender",
            :company => "Catprint",
            :phone_number => "555-555-5555",
            :address => "None",
            :city => "None",
            :state => Fedex::UpsInfo.state_from_zip("#{fromZipCode}"),
            :postal_code => "#{fromZipCode}",
            :country_code => "US" 
          }
            
recipient = { :name => "Recipient",
              :company => "Company",
              :phone_number => "555-555-5555",
              :address => "Main Street",
              :city => "None",
              :state => Fedex::UpsInfo.state_from_zip("#{toZipCode}"),
              :postal_code => "#{toZipCode}",
              :country_code => "US",
              :residential => "false" 
            }
              
packages = []
packages << { :weight => {:units => "LB", :value => weight},
              :dimensions => {:length => 10, :width => 5, :height => 4, :units => "IN" }
            }

shipping_details = { :packaging_type => "YOUR_PACKAGING",
                     :drop_off_type => "REGULAR_PICKUP"
                   }

rate = fedex.rate( :shipper=>shipper,
                   :recipient => recipient,
                   :packages => packages,
                   :service_type => "FEDEX_GROUND",
                   :shipping_details => shipping_details
                  )
                 
       
ship = fedex.ship(:shipper=>shipper,
                  :recipient => recipient,
                  :packages => packages,
                  :service_type => "FEDEX_GROUND",
                  :shipping_details => shipping_details
                  )
                  

# UPS Info

access_options = {  :access_license_number => '9CA349F0CB25A9DB',
                    :user_id => 'piyushkp',
                    :password => 'Admin123#',
                    :order_cutoff_time => 17 ,
                    :sender_city => 'None',
                    :sender_state => Fedex::UpsInfo.state_from_zip("#{fromZipCode}"),
                    :sender_zip => "#{fromZipCode}",
                    :sender_country_code => 'US'
                  }
  
request_options = { :total_packages => 1,
                    :unit_of_measurement => 'LBS',
                    :weight => 10,
                    :city => 'None',
                    :state => Fedex::UpsInfo.state_from_zip("#{toZipCode}"),
                    :zip => "#{toZipCode}",
                    :country_code => 'US',
                    :mode => 'test'
                  }
  
upsInfo = Fedex::UpsInfo.new(access_options)



shippingInfo = {  "Fedex Price" => rate.total_net_charge,  
                  "Fedex ground_transit" => ship[:completed_shipment_detail][:operational_detail] [:transit_time],
                  "UPS Price" => upsInfo.getPrice(request_options),
                  "UPS GND Transit days" => upsInfo.getTransitTime(request_options)
               } 

return shippingInfo

end
end

my_object = ShippingInfo.new
results = my_object.Shipping_Info "48503", "12776", "10"

puts results



                  