require 'date'
require 'time'
require 'rexml/document'
require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'

module Fedex
  # Provides a simple api to to ups's time in transit service.
  class UpsInfo
    
    TEST_URL = "https://wwwcie.ups.com/ups.app/xml"

    # UPS Production URL
    PRODUCTION_URL = "https://onlinetools.ups.com/ups.app/xml"
    
    XPCI_VERSION = '1.0002'
    DEFAULT_CUTOFF_TIME = 14
    DEFAULT_TIMEOUT = 30
    DEFAULT_RETRY_COUNT = 3
    DEFAULT_COUNTRY_CODE = 'US'
    DEFAULT_UNIT_OF_MEASUREMENT = 'LBS'

    def initialize(access_options)
      @order_cutoff_time = access_options[:order_cutoff_time] || DEFAULT_CUTOFF_TIME      
      @timeout = access_options[:timeout] || DEFAULT_TIMEOUT 
      @retry_count = access_options[:retry_count] || DEFAULT_CUTOFF_TIME 

      @access_xml = generate_xml({
        :AccessRequest => {
          :AccessLicenseNumber => access_options[:access_license_number],
          :UserId => access_options[:user_id],
          :Password => access_options[:password]
        }
      })

      @transit_from_attributes = {
        :AddressArtifactFormat => {
          :PoliticalDivision2 => access_options[:sender_city],
          :PoliticalDivision1 => access_options[:sender_state],
          :CountryCode => access_options[:sender_country_code] || DEFAULT_COUNTRY_CODE,
          :PostcodePrimaryLow => access_options[:sender_zip]
        }
      }
      
       @rate_from_attributes = {
        :Address => {
          :City => access_options[:sender_city],
          :StateProvinceCode => access_options[:sender_state],
          :CountryCode => access_options[:sender_country_code] || DEFAULT_COUNTRY_CODE,
          :PostalCode => access_options[:sender_zip]
         }
        }
      
    end

    def getPrice (options)
      
      @url = options[:mode] == "production" ? PRODUCTION_URL : TEST_URL + '/Rate'
      
      #@url = options[:url] + '/Rate'
      # build our request xml 
      
      xml = @access_xml + generate_xml(build_price_attributes(options))
      #puts xml
      # attempt the request in a timeout
      delivery_price = 0
      
      begin 
        Timeout.timeout(@timeout) do
          response = send_request(@url, xml)
          delivery_price = response_to_price(response)
      end
      delivery_price
    end
   end

    def getTransitTime(options)
      
      @url = options[:mode] == "production" ? PRODUCTION_URL : TEST_URL + '/TimeInTransit'
      #@url = options[:url] + '/TimeInTransit'
      # build our request xml
      pickup_date = calculate_pickup_date
      options[:pickup_date] = pickup_date.strftime('%Y%m%d')
      xml = @access_xml + generate_xml(build_transit_attributes(options))
      
      # attempt the request in a timeout
      delivery_dates = {}
      attempts = 0
      begin 
        Timeout.timeout(@timeout) do
          response = send_request(@url, xml)
          delivery_dates = response_to_map(response)
        end

      # We can only attempt to recover from Timeout errors, all other errors
      # should be raised back to the user
      rescue Timeout::Error => error
        if(attempts < @retry_count)
          attempts += 1
          retry

        else
          raise error
        end
      end

      delivery_dates
    end

    private 

    # calculates the next available pickup date based on the current time and the 
    # configured order cutoff time
    def calculate_pickup_date
      now = Time.now
      day_of_week = now.strftime('%w').to_i
      in_weekend = [6,0].include?(day_of_week)
      in_friday_after_cutoff = day_of_week == 5 and now.hour > @order_cutoff_time

      # If we're in a weekend (6 is Sat, 0 is Sun,) or we're in Friday after
      # the cutoff time, then our ship date will move
      if(in_weekend or in_friday_after_cutoff)
        pickup_date = now

      # if we're in another weekday but after the cutoff time, our ship date
      # moves to tomorrow
      elsif(now.hour > @order_cutoff_time)
        pickup_date = now
      else
        pickup_date = now
      end
    end

    # Builds a hash of transit request attributes based on the given values
    def build_transit_attributes(options)
      # set defaults if none given
      options[:total_packages] = 1 unless options[:total_packages]

      # convert all options to string values
      options.each_value {|option| option = options.to_s}

      transit_attributes = {
        :TimeInTransitRequest => {
          :Request => {
            :RequestAction => 'TimeInTransit',
            :TransactionReference => {
              :XpciVersion => XPCI_VERSION
            }
          },
          :TotalPackagesInShipment => options[:total_packages],
          :ShipmentWeight => {
            :UnitOfMeasurement => {
              :Code => options[:unit_of_measurement] || DEFAULT_UNIT_OF_MEASUREMENT
            },
            :Weight => options[:weight],
          },
          :PickupDate => options[:pickup_date],
          :TransitFrom => @transit_from_attributes,
          :TransitTo => {
            :AddressArtifactFormat => {
              :PoliticalDivision2 => options[:city],
              :PoliticalDivision1 => options[:state],
              :CountryCode => options[:country_code] || DEFAULT_COUNTRY_CODE,
              :PostcodePrimaryLow => options[:zip],
            }
          }
        }
      }
    end

 # Builds a hash of price attributes based on the given values
    def build_price_attributes(options)
      # convert all options to string values
      options.each_value {|option| option = options.to_s}

      rate_attributes = {
        :RatingServiceSelectionRequest => {
          :Request => {
            :RequestAction => 'Rate',
            :RequestOption => 'Rate',
            :TransactionReference => {
              :XpciVersion => '1.0'}
              },
            :PickupType => {
              :Code => '01'
            },
            :CustomerClassification => {:Code => '01'},
            :Shipment => {
              :Shipper => @rate_from_attributes,
              :ShipTo => {:Address => {
                :City => options[:city],
                :StateProvinceCode => options[:state],
                :PostalCode => options[:zip],
                :CountryCode => options[:country_code]}
                },
               :Service => {:Code => '03'},
               :Package => {:PackagingType => {:Code => '02'},
               :PackageWeight => {:Weight => options[:weight], :UnitOfMeasurement => 'LBS'}
               }
              }            
           }
        }
    end

    # generates an xml document for the given attributes
    def generate_xml(attributes)
      xml = REXML::Document.new
      xml << REXML::XMLDecl.new
      emit(attributes, xml)
      xml.root.add_attribute("xml:lang", "en-US")
      xml.to_s
    end

    # recursively emits xml nodes under the given node for values in the given hash
    def emit(attributes, node)
      attributes.each do |k,v|
        child_node = REXML::Element.new(k.to_s, node)
        (v.respond_to? 'each_key') ? emit(v, child_node) : child_node.add_text(v.to_s)
      end
    end

    # Posts the given data to the given url, returning the raw response
    def send_request(url, data)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.port == 443
        http.use_ssl	= true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.post(uri.path, data)
      response.code == '200' ? response.body : response.error!
    end

    # converts the given raw xml response to a map of local service codes
    # to estimated delivery dates
    def response_to_map(response) 
      response_doc = REXML::Document.new(response)
      response_code = response_doc.elements['//ResponseStatusCode'].text.to_i
      raise "Invalid response from ups:\n#{response_doc.to_s}" if(!response_code || response_code != 1)
      delivery_date = 0
      service_codes_to_delivery_dates = {}
      response_code = response_doc.elements.each('//ServiceSummary') do |service_element|
        service_code = service_element.elements['Service/Code'].text
        if(service_code == "GND")
          date_string = service_element.elements['EstimatedArrival/Date'].text
          pickup_date = service_element.elements['EstimatedArrival/PickupDate'].text
          #time_string = service_element.elements['EstimatedArrival/Time'].text
          #delivery_date = Time.parse("#{date_string}")
          delivery_date = (Time.parse(date_string) - Time.parse(pickup_date)) / 86400
          #service_codes_to_delivery_dates[ "UPS 12"+ service_code + " Transit Days"] = delivery_date
        end
      end
      delivery_date
      #response
    end   
    
    def response_to_price(response) 
      #puts response
      response_doc = REXML::Document.new(response)
      response_code = response_doc.elements['//ResponseStatusCode'].text.to_i
      raise "Invalid response from ups:\n#{response_doc.to_s}" if(!response_code || response_code != 1)
      delivery_rate = 0
      
      delivery_rate = response_doc.elements['//RatedShipment/TotalCharges/MonetaryValue'].text.to_f     
      
      delivery_rate
      #response
    end
    
    def self.state_from_zip(zip)
      zip = zip.to_i
      {
        (99500...99929) => "AK", 
        (35000...36999) => "AL", 
        (71600...72999) => "AR", 
        (75502...75505) => "AR", 
        (85000...86599) => "AZ", 
        (90000...96199) => "CA", 
        (80000...81699) => "CO", 
        (6000...6999) => "CT", 
        (20000...20099) => "DC", 
        (20200...20599) => "DC", 
        (19700...19999) => "DE", 
        (32000...33999) => "FL", 
        (34100...34999) => "FL", 
        (30000...31999) => "GA", 
        (96700...96798) => "HI", 
        (96800...96899) => "HI", 
        (50000...52999) => "IA", 
        (83200...83899) => "ID", 
        (60000...62999) => "IL", 
        (46000...47999) => "IN", 
        (66000...67999) => "KS", 
        (40000...42799) => "KY", 
        (45275...45275) => "KY", 
        (70000...71499) => "LA", 
        (71749...71749) => "LA", 
        (1000...2799) => "MA", 
        (20331...20331) => "MD", 
        (20600...21999) => "MD", 
        (3801...3801) => "ME", 
        (3804...3804) => "ME", 
        (3900...4999) => "ME", 
        (48000...49999) => "MI", 
        (55000...56799) => "MN", 
        (63000...65899) => "MO", 
        (38600...39799) => "MS", 
        (59000...59999) => "MT", 
        (27000...28999) => "NC", 
        (58000...58899) => "ND", 
        (68000...69399) => "NE", 
        (3000...3803) => "NH", 
        (3809...3899) => "NH", 
        (7000...8999) => "NJ", 
        (87000...88499) => "NM", 
        (89000...89899) => "NV", 
        (400...599) => "NY", 
        (6390...6390) => "NY", 
        (9000...14999) => "NY", 
        (43000...45999) => "OH", 
        (73000...73199) => "OK", 
        (73400...74999) => "OK", 
        (97000...97999) => "OR", 
        (15000...19699) => "PA", 
        (2800...2999) => "RI", 
        (6379...6379) => "RI", 
        (29000...29999) => "SC", 
        (57000...57799) => "SD", 
        (37000...38599) => "TN", 
        (72395...72395) => "TN", 
        (73300...73399) => "TX", 
        (73949...73949) => "TX", 
        (75000...79999) => "TX", 
        (88501...88599) => "TX", 
        (84000...84799) => "UT", 
        (20105...20199) => "VA", 
        (20301...20301) => "VA", 
        (20370...20370) => "VA", 
        (22000...24699) => "VA", 
        (5000...5999) => "VT", 
        (98000...99499) => "WA", 
        (49936...49936) => "WI", 
        (53000...54999) => "WI", 
        (24700...26899) => "WV", 
        (82000...83199) => "WY"
        }.each do |range, state|
          return state if range.include? zip
        end

        raise ShippingError, "Invalid zip code"
      end
 
    
  end
end
