require 'shipping'
    
     #ups = Shipping::UPS.new :zip => 97202, :state => "OR", :sender_zip => 10001, :weight => 2, :ups_license_number => "9CA349F0CB25A9DB", :ups_user =>"piyushkp", :ups_password =>"Admin123#"
     
     
     ups = Shipping::UPS.new :zip => 97202, 
                          :sender_zip => 10001, 
                          :weight => 2, 
                          :ups_license_number => "9CA349F0CB25A9DB", 
                          :ups_user =>"piyushkp", 
                          :ups_password =>"Admin123#",
                          :mode => 'test'
    puts ups.price