#! /usr/bin/ruby -rrubygems


xml_request = "<PostageRateRequest>
  <RequesterID>abcd</RequesterID> 
  <CertifiedIntermediary>
     <AccountID>123456</AccountID>
     <PassPhrase>samplePassPhrase</PassPhrase>
     </CertifiedIntermediary>
  <MailClass>Priority</MailClass> 
     <WeightOz>8.7</WeightOz> <MailpieceShape>Parcel</MailpieceShape> <Machinable>True</Machinable> 
     <Services DeliveryConfirmation='OFF' SignatureConfirmation='ON'/> <FromPostalCode>95747</FromPostalCode>  
     <ToPostalCode>94301</ToPostalCode> <ResponseOptions PostagePrice='TRUE'/>
</PostageRateRequest>"

URL = "https://www.envmgr.com/LabelService/EwsLabelService.asmx/CalculatePostageRateXML"
require "curl"

c = Curl::Easy.http_post(URL, Curl::PostField.content('postageRateRequestXML', xml_request))
c.follow_location = true
c.ssl_verify_host = false
puts c.body_str