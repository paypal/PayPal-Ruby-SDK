require 'spec_helper'

describe PayPal::SDK::OpenIDConnect do
  OpenIDConnect = PayPal::SDK::OpenIDConnect

  before :all do
    OpenIDConnect.set_config( :client_id => "client_id", :openid_redirect_uri => "http://google.com" )
  end

  it "Validate user_agent" do
    expect(OpenIDConnect::API.user_agent).to match "PayPalSDK/openid-connect-ruby"
  end

  describe "generate_authorize_url" do

    it "generate autorize_url" do
      url = OpenIDConnect::Tokeninfo.authorize_url
      expect(url).to match "client_id=client_id"
      expect(url).to match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
      expect(url).to match "scope=openid"
    end

    describe "sandbox" do
      before do
        PayPal::SDK.configure(:mode => "sandbox")
      end

      it "generates a sandbox authorize url" do
        url = OpenIDConnect::Tokeninfo.authorize_url
        expect(url).to match "sandbox.paypal.com"
      end
    end
  end

  it "Override authorize_url params" do
    url = OpenIDConnect.authorize_url(
      :client_id => "new_client_id",
      :redirect_uri => "http://example.com",
      :scope => "openid profile")
    expect(url).to match "client_id=new_client_id"
    expect(url).to match Regexp.escape("redirect_uri=#{CGI.escape("http://example.com")}")
    expect(url).to match Regexp.escape("scope=#{CGI.escape("openid profile")}")
  end

  it "Generate logout_url" do
    url = OpenIDConnect.logout_url
    expect(url).to match "logout=true"
    expect(url).to match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
    expect(url).not_to match "id_token"
  end

  it "Override logout_url params" do
    url = OpenIDConnect.logout_url({
      :redirect_uri => "http://example.com",
      :id_token  => "testing" })
    expect(url).to match Regexp.escape("redirect_uri=#{CGI.escape("http://example.com")}")
    expect(url).to match "id_token=testing"
  end

  describe "Validation" do
    it "Create token" do
      expect{
        tokeninfo = OpenIDConnect::Tokeninfo.create("invalid-autorize-code")
      }.to raise_error PayPal::SDK::Core::Exceptions::BadRequest
    end

    it "Refresh token" do
      expect{
        tokeninfo = OpenIDConnect::Tokeninfo.refresh("invalid-refresh-token")
      }.to raise_error PayPal::SDK::Core::Exceptions::BadRequest
    end

    it "Get userinfo" do
      expect{
        userinfo = OpenIDConnect::Userinfo.get("invalid-access-token")
      }.to raise_error PayPal::SDK::Core::Exceptions::UnauthorizedAccess
    end
  end

  describe "Tokeninfo" do
    before do
      @tokeninfo = OpenIDConnect::Tokeninfo.new( :access_token => "test_access_token",
        :refresh_token => "test_refresh_token",
        :id_token => "test_id_token" )
    end

    it "create" do
      allow(OpenIDConnect::Tokeninfo.api).to receive_messages( :post => { :access_token => "access_token" } )
      tokeninfo = OpenIDConnect::Tokeninfo.create("authorize_code")
      expect(tokeninfo).to be_a OpenIDConnect::Tokeninfo
      expect(tokeninfo.access_token).to eql "access_token"
    end

    it "refresh" do
      allow(@tokeninfo.api).to receive_messages( :post => { :access_token => "new_access_token" } )
      expect(@tokeninfo.access_token).to eql "test_access_token"
      @tokeninfo.refresh
      expect(@tokeninfo.access_token).to eql "new_access_token"
    end

    it "userinfo" do
      allow(@tokeninfo.api).to receive_messages( :post => { :name => "Testing" } )
      userinfo = @tokeninfo.userinfo
      expect(userinfo).to be_a OpenIDConnect::Userinfo
      expect(userinfo.name).to eql "Testing"
    end

    describe "logout_url" do
      it "Generate logout_url" do
        url = @tokeninfo.logout_url
        expect(url).to match "id_token=test_id_token"
        expect(url).to match "logout=true"
        expect(url).to match Regexp.escape("redirect_uri=#{CGI.escape("http://google.com")}")
      end

      describe "sandbox" do
        before do
          PayPal::SDK.configure(:mode => "sandbox")
        end

        it "generates a sandbox logout url" do
          url = @tokeninfo.logout_url
          expect(url).to match "sandbox.paypal.com"
        end
      end
    end
  end

  describe "Userinfo" do
    it "get" do
      allow(OpenIDConnect::Userinfo.api).to receive_messages( :post => { :name => "Testing" } )

      userinfo = OpenIDConnect::Userinfo.get("access_token")
      userinfo = OpenIDConnect::Userinfo.new( { :name => "Testing" } )
      expect(userinfo).to be_a OpenIDConnect::Userinfo
      expect(userinfo.name).to eql "Testing"

      userinfo = OpenIDConnect::Userinfo.get( :access_token => "access_token" )
      expect(userinfo).to be_a OpenIDConnect::Userinfo
      expect(userinfo.name).to eql "Testing"
    end

    it "get", :integration => true do
      api = PayPal::SDK::REST::API.new
      access_token = api.token_hash()
      userinfo = OpenIDConnect::Userinfo.get( access_token )
      expect(userinfo).to be_a OpenIDConnect::Userinfo
      expect(userinfo.email).to eql "jaypatel512-facilitator@hotmail.com"
    end
  end

  describe "auth_assertion_header" do
      it "generate an auth assertion header" do
        alg = {"alg":"none"}
        api = PayPal::SDK::REST::API.new
        auth_assertion = api.auth_assertion_header()
        expect(Base64.decode64(auth_assertion).force_encoding('UTF-8')).to match alg.to_json
      end

      it "generate an auth assertion header with email" do
        alg = {"alg":"none"}
        payload = {"email":"test@paypal.com", "iss":"AYSq3RDGsmBLJE-otTkBtM-jBRd1TCQwFf9RGfwddNXWz0uFU9ztymylOhRS"}
        api = PayPal::SDK::REST::API.new
        auth_assertion = api.auth_assertion_header("test@paypal.com")
        auth_assertion_array = auth_assertion.split(/[\s.]/)
        expect(Base64.decode64(auth_assertion_array[0]).force_encoding('UTF-8')).to match alg.to_json
        expect(Base64.decode64(auth_assertion_array[1]).force_encoding('UTF-8')).to match payload.to_json
      end

      it "generate an auth assertion header with payer id" do
        alg = {"alg":"none"}
        payload = {"payer_id":"TEST12345", "iss":"AYSq3RDGsmBLJE-otTkBtM-jBRd1TCQwFf9RGfwddNXWz0uFU9ztymylOhRS"}
        api = PayPal::SDK::REST::API.new
        auth_assertion = api.auth_assertion_header("TEST12345", true)
        auth_assertion_array = auth_assertion.split(/[\s.]/)
        expect(Base64.decode64(auth_assertion_array[0]).force_encoding('UTF-8')).to match alg.to_json
        expect(Base64.decode64(auth_assertion_array[1]).force_encoding('UTF-8')).to match payload.to_json
      end
  end



end
