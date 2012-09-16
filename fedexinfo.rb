require 'fedex'
class FedexInfo

def Fedex_Info (fromZipCode, toZipCode, weight)
  
fedex = Fedex::Shipment.new(:key => 'Uo5ehu0ZVJIkwN4y',
                            :password => 'KXOH9K5coupax3FF4bM1opp9M',
                            :account_number => '510087046',
                            :meter => '118564789',
                            :mode => 'test')
                            
                            
shipper = { :name => "Sender",
            :company => "Company",
            :phone_number => "555-555-5555",
            :address => "Main Street",
            :city => "Harrison",
            :state => "AR",
            :postal_code => "#{fromZipCode}",
            :country_code => "US" }
            
recipient = { :name => "Recipient",
              :company => "Company",
              :phone_number => "555-555-5555",
              :address => "Main Street",
              :city => "Franklin Park",
              :state => "IL",
              :postal_code => "#{toZipCode}",
              :country_code => "US",
              :residential => "false" }
              
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
 
fedexInfo = { "total_net_charge" => rate.total_net_charge,  
              "ground_transit" => ship[:completed_shipment_detail][:operational_detail] [:transit_time]
            } 

return fedexInfo

end
end

my_object = FedexInfo.new
results = my_object.Fedex_Info "72601","60131","30"

puts results



                  