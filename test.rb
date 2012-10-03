require 'fedex'

access_options = {
  :access_license_number => '9CA349F0CB25A9DB',
  :user_id => 'piyushkp',
  :password => 'Admin123#',
  :order_cutoff_time => 17 ,
  :sender_city => 'Hoboken',
  :sender_state => 'MI',
  :sender_country_code => 'US',
  :sender_zip => '48503'}
  
request_options = {
  :mode => 'test',
  :total_packages => 1,
  :unit_of_measurement => 'LBS',
  :weight => 10,
  :city => 'Newark',
  :state => 'NY',
  :zip => '12776',
  :country_code => 'US'}
  
upsInfo = Fedex::UpsInfo.new(access_options)

begin    

 delivery_dates = {"UPS GND Transit days" => upsInfo.getTransitTime(request_options)}
 delivery_rate = upsInfo.getPrice(request_options)
 puts delivery_rate
 puts delivery_dates
end